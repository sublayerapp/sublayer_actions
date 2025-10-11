require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for triggering a Zapier webhook with custom payload data.
# This action allows integration with thousands of apps through Zapier's webhook functionality,
# enabling complex automation workflows to be triggered from Sublayer actions.
#
# It is initialized with a webhook_url and payload data to send to Zapier.
# It returns the HTTP response code to confirm the webhook was triggered successfully.
#
# Example usage: When you want to trigger a Zapier automation from an AI workflow,
# such as creating records in a CRM, sending emails, or updating spreadsheets.

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
        Sublayer.configuration.logger.log(:info, 'Successfully triggered Zapier webhook')
        response.code.to_i
      else
        error_message = "Failed to trigger Zapier webhook. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue URI::InvalidURIError => e
      error_message = "Invalid webhook URL: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue SocketError => e
      error_message = "Network error while triggering webhook: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error triggering Zapier webhook: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end