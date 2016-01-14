#!/usr/bin/env ruby

require 'octokit'
require 'dotenv'
require 'slack-notifier'

Dotenv.load

# GitHub Enteprise API Endpoint: "https://<hostname>/api/v3"
Octokit.configure do |c|
  c.api_endpoint = ENV['OCTOKIT_API_ENDPOINT']
  c.login = ENV['GHE_LOGIN_USERNAME']
  c.password = ENV['GHE_LOGIN_PASSWORD']
end

license = Octokit.license_info

seats = license[:seats]
seats_used = license[:seats_used]
seats_available = license[:seats_available]

a_ok_note = {
  'color' => 'good',
  'fields' => [
    {
      'title' => 'Information',
      'value' => "Seats Total: #{seats}\nSeats Used: #{seats_used}\nSeats Available: #{seats_available}",
      'short' => false
    },
    {
      'title' => 'Status',
      'value' => 'good',
      'short' => false
    }
  ]
}

a_ng_note = {
  'color' => 'danger',
  'fields' => [
    {
      'title' => 'Information',
      'value' => "Seats Total: #{seats}\nSeats Used: #{seats_used}\nSeats Available: #{seats_available}",
      'short' => false
    },
    {
      'title' => 'Status',
      'value' => 'danger',
      'short' => false
    }
  ]
}

notify_user = ENV['SLACK_USER'] || 'notifier'
danger_threshold = ENV['GHE_SEATS_DANGER_THRESHOLD'] || 0

notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK'], :username => notify_user
if seats_available.to_i > danger_threshold.to_i
  notifier.ping 'GitHub Enterprise Seats Checker',
                'icon_emoji' => ENV['SLACK_ICON_EMOJI'],
                'attachments' => [a_ok_note]
else
  notifier.ping 'GitHub Enterprise Seats Checker',
                'icon_emoji' => ENV['SLACK_ICON_EMOJI'],
                'attachments' => [a_ng_note]
end
