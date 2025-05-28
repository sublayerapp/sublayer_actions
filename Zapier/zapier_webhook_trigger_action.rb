require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for triggering a Zapier webhook with custom payload data.
# This action enables integration with thousands of apps through Zapier's automation platform,
# allowing Sublayer workflows to connect with virtually any service that Zapier supports.
#
# It is initialized with a webhook_url and payload data.
# It returns the HTTP response code to confirm the webhook was triggered successfully.
#
# Example usage: When you want to send AI-processed data to other applications through Zapier,
# such as creating records in a CRM, sending notifications, or updating spreadsheets.

class ZapierWebhookTriggerAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload:)
    @webhook_url = webhook_url
    @payload = payload
  end

  def call
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = @payload.to_json

    begin
      response = http.request(request)
      case response.code.to_i
      when 200..299
        Sublayer.configuration.logger.log(:info, "Successfully triggered Zapier webhook")
        response.code.to_i
      else
        error_message = "Failed to trigger Zapier webhook. HTTP Response Code: #{response.code} - #{response.body}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue URI::InvalidURIError => e
      error_message = "Invalid webhook URL: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue JSON::ParserError => e
      error_message = "Invalid JSON payload: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error triggering Zapier webhook: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end