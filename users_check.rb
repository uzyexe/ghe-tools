#!/usr/bin/env ruby

require 'octokit'
require 'dotenv'
require 'net/ldap'
require 'json'
require 'slack-notifier'

Dotenv.load

# ghost: Reserved user IDs
exclude_users = %w(ghost)

# LDAP Connection Settings
LDAP_SERVER = ENV['LDAP_SERVER']
LDAP_PORT   = ENV['LDAP_PORT'] || 389
LDAP_BASE   = ENV['LDAP_BASE']

# GitHub Enteprise API Endpoint: "https://<hostname>/api/v3"
Octokit.configure do |c|
  c.api_endpoint = ENV['OCTOKIT_API_ENDPOINT']
end

# Auto pagination (Requests that return multiple items will be paginated to 30 items by default.)
# https://developer.github.com/v3/#pagination
Octokit.auto_paginate = true

users   = []
last_id = 0

loop do
  Octokit.all_users(:since => last_id).each do |user|
    next unless user.type == 'User'
    next if exclude_users.include?(user.login)
    users << { :id => user.id, :login => user.login }
  end
  break if last_id == users[-1][:id]
  last_id = users[-1][:id]
end

success = 0
failed  = 0
message  = ''

net_ldap = Net::LDAP.new :host => LDAP_SERVER, :port => LDAP_PORT, :base => LDAP_BASE
users.each do |user|
  login = user[:login]
  username = Octokit.user(login).name
  status = Octokit.user(login).suspended_at
  net_ldap.open do |ldap|
    filter = Net::LDAP::Filter.eq('uid', username)
    attrs = 'uid'
    search = ldap.search(:base => LDAP_BASE, :filter => filter, :attributes => attrs, :attributes_only => true) do |entry|
      entry.each do |_attr, values|
        values.each do |value|
          if value.match(/^uid=(#{username}),.*$/) && status.nil?
            success += 1
          else
            failed += 1
            message = message + username + ": Suspended user.\n"
          end
        end
      end
    end
    if search.empty?
      failed += 1
      message = message + username + ": Does not exist user.\n"
    end
  end
  sleep(0.1)
end

a_ok_note = {
  'fallback' => 'GitHub Enterprise Users Checker',
  'text' => 'good',
  'color' => 'good'
}

a_ng_note = {
  'color' => 'danger',
  'fields' => [
    {
      'title' => 'Log',
      'value' => message,
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

notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK'], :username => notify_user
if failed == 0
  notifier.ping 'GitHub Enterprise Users Checker',
                'icon_emoji' => ENV['SLACK_ICON_EMOJI'],
                'attachments' => [a_ok_note]
else
  notifier.ping 'GitHub Enterprise Users Checker',
                'icon_emoji' => ENV['SLACK_ICON_EMOJI'],
                'attachments' => [a_ng_note]
end
