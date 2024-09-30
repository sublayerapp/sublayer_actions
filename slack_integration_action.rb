# frozen_string_literal: true

module Sublayer
  module Actions
    class SlackIntegrationAction < Sublayer::Actions::Base
      require 'net/http'
      require 'json'

      attr_reader :webhook_url, :channel, :username, :icon_emoji

      def initialize(webhook_url:, channel:, username: 'SublayerBot', icon_emoji: ':robot_face:')
        @webhook_url = webhook_url
        @channel = channel
        @username = username
        @icon_emoji = icon_emoji
      end

      def call(event_data)
        message = create_message(event_data)
        response = send_to_slack(message)
        log_response(response)
      rescue StandardError => e
        log_error(e.message)
      end

      private

      def create_message(event_data)
        "Alert: An event has occurred - #{event_data[:description]}"
      end

      def send_to_slack(message)
        uri = URI(webhook_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        req = Net::HTTP::Post.new(uri, 'Content-Type' => 'application/json')
        req.body = {
          channel: channel,
          username: username,
          text: message,
          icon_emoji: icon_emoji
        }.to_json

        http.request(req)
      end

      def log_response(response)
        if response.is_a?(Net::HTTPSuccess)
          puts "[SlackIntegrationAction] Message successfully sent to Slack channel: #{channel}."
        else
          puts "[SlackIntegrationAction] Failed to send message to Slack. Response: #{response.body}."
        end
      end

      def log_error(error_message)
        puts "[SlackIntegrationAction] Error encountered: #{error_message}."
      end
    end
  end
end
