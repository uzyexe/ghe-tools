#!/usr/bin/env ruby

require 'octokit'
require 'dotenv'
require 'slack-notifier'

Dotenv.load

# GitHub Enteprise API Endpoint: "https://<hostname>/api/v3"
Octokit.configure do |c|
  c.api_endpoint = ENV['OCTOKIT_API_ENDPOINT']
  c.login = 'uzyexe'
  c.password = 'df86ce335965556eef01e37eab34e9083cb417bb'
end

license = Octokit.license_info

seats = license[:seats]
seats_used = license[:seats_used]
seats_available = license[:seats_available]

a_ok_note = {
  'fallback' => 'GitHub Enterprise License Information',
  'text' => "Seats Total: #{seats}\nSeats Used: #{seats_used}\nSeats Available: #{seats_available}",
  'color' => 'good'
}

a_ng_note = {
  'fallback' => 'GitHub Enterprise License Information',
  'text' => "Seats Total: #{seats}\nSeats Used: #{seats_used}\nSeats Available: #{seats_available}",
  'color' => 'danger'
}

notify_user = ENV['SLACK_USER'] || 'notifier'
danger_threshold = ENV['GHE_SEATS_DANGER_THRESHOLD'] || 0

notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK'], :username => notify_user
if seats_available.to_i > danger_threshold.to_i
  notifier.ping 'ghe-tools: GitHub Enterprise Seats Checker',
                'icon_emoji' => ENV['SLACK_ICON_EMOJI'],
                'attachments' => [a_ok_note]
else
  notifier.ping 'ghe-tools: GitHub Enterprise Seats Checker',
                'icon_emoji' => ENV['SLACK_ICON_EMOJI'],
                'attachments' => [a_ng_note]
end
