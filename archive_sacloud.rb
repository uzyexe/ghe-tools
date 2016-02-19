#!/usr/bin/env ruby

require 'active_support/time'
require 'timecop'
require 'saklient/cloud/api'
require 'socket'
require 'dotenv'
require 'slack-notifier'

Dotenv.load

# common settings
zone = ENV['SACLOUD_ZONE']
token = ENV['SACLOUD_TOKEN']
secret = ENV['SACLOUD_SECRET']
disk_port = ARGV[0]

# archive settings
source_server_id = ENV['SACLOUD_SERVER_ID']
source_disk_base_name = ENV['SACLOUD_DISK_NAME']
archive_description = ENV['SACLOUD_DESCRIPTION']
archive_tag = ENV['SACLOUD_ARCHIVE_TAG']
archive_rotation = ENV['SACLOUD_ARCHIVE_ROTATION'] || 3

api = Saklient::Cloud::API.authorize(token, secret, zone)

# puts 'searching disks...'
disk_name = "#{source_disk_base_name}#{disk_port}"
disks = api.disk.with_name_like(disk_name).with_server_id(source_server_id).find
# printf "found %d disk(s)\n", disks.length
disk = disks[0]

# puts 'create archive...'
archive = api.archive.create
archive.name = source_disk_base_name + disk_port + '-' + DateTime.now.strftime('%Y%m%d_%H:%M:%S')
archive.description = archive_description
archive.tags = [archive_tag]
archive.source = disk
# puts 'Source disk Name: ' + disk.name
# puts 'Source disk ID  : ' + disk.id
# puts 'disk copy to archive...'

# slack post settings
def post(title, target, message, color)
  a_message_note = {
    'color' => color,
    'fields' => [
      {
        'title' => 'Message',
        'value' => message,
        'short' => false
      },
      {
        'title' => 'Archive Name',
        'value' => target,
        'short' => true
      },
      {
        'title' => 'Status',
        'value' => color,
        'short' => false
      }
    ]
  }

  notify_user = ENV['SLACK_USER'] || 'notifier'
  notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK'], :username => notify_user
  notifier.ping title, 'icon_emoji' => ENV['SLACK_ICON_EMOJI'], 'attachments' => [a_message_note]
end

begin
  archive.save
  archive.sleep_while_copying
  slack_msg = 'Success'
  color = 'good'
rescue
  slack_msg = $ERROR_INFO
  color = 'danger'
ensure
  post('GitHub Enterprise Save Archive (Sacloud)', archive.name, slack_msg, color)
end

# puts 'searching target archive...'
archives = api.archive.with_name_like(source_disk_base_name + disk_port).with_tag(archive_tag).find
# printf "found %d archive(s)\n", archives.length

# puts 'delete old archive...'
archives.length.times do |i|
  archives[i].name.match(/#{source_disk_base_name}#{disk_port}-(\d+)_.*/)
  rotation = Timecop.travel("#{archive_rotation}".to_i.days.ago).strftime '%Y%m%d'
  next unless rotation.to_i > Regexp.last_match[1].to_i
  begin
    # puts 'Destroy: ' + archives[i].name + ' < ' + rotation.to_s
    archives[i].destroy
    slack_msg = 'Success'
    color = 'good'
  rescue
    slack_msg = $ERROR_INFO
    color = 'danger'
  ensure
    post('Destroy Old Archive (Sacloud)', archives[i].name, slack_msg, color)
  end
end
