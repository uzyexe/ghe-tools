#!/usr/bin/env ruby

require 'octokit'
require 'dotenv'
require 'slack-notifier'

Dotenv.load

user = ARGV[0]
email = ARGV[1]

# GitHub Enteprise API Endpoint: "https://<hostname>/api/v3"
Octokit.configure do |c|
  c.api_endpoint = ENV['OCTOKIT_API_ENDPOINT']
  c.login = ENV['GHE_LOGIN_USERNAME']
  c.password = ENV['GHE_LOGIN_PASSWORD']
end

Octokit.create_user(user, email)
