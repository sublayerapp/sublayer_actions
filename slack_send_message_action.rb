module Sublayer
  module Actions
    class SlackSendMessageAction < Sublayer::Actions::Base
      require 'net/http'
      require 'uri'
      require 'json'

      def initialize(webhook_url, channel, username = 'SublayerBot', icon_emoji = ':robot_face:')
        @webhook_url = webhook_url
        @channel = channel
        @username = username
        @icon_emoji = icon_emoji
        validate_params
      end

      def call(message, attachments = [])
        payload = {
          channel: @channel,
          username: @username,
          icon_emoji: @icon_emoji,
          text: message,
          attachments: attachments
        }

        begin
          uri = URI.parse(@webhook_url)
          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true
          request = Net::HTTP::Post.new(uri.request_uri, 'Content-Type' => 'application/json')
          request.body = payload.to_json

          response = http.request(request)
          handle_response(response)
        rescue StandardError => e
          log_error("Failed to send message to Slack: #{e.message}")
          raise "SlackSendMessageAction failed with error: #{e.message}"
        end
      end

      private

      def validate_params
        raise ArgumentError, 'Invalid webhook URL' unless valid_url?(@webhook_url)
        raise ArgumentError, 'Channel cannot be empty' if @channel.to_s.strip.empty?
      end

      def valid_url?(url)
        uri = URI.parse(url)
        uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      rescue URI::InvalidURIError
        false
      end

      def handle_response(response)
        case response
        when Net::HTTPSuccess
          log_info('Message sent successfully to Slack.')
        else
          log_error("Error sending message to Slack: #{response.message}")
          raise "SlackSendMessageAction failed with HTTP response code: #{response.code}"
        end
      end
    end
  end
end