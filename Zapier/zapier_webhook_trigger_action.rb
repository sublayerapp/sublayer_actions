require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for triggering a Zapier webhook with custom data.
# This action enables integration with thousands of apps through Zapier's webhook functionality,
# allowing Sublayer workflows to connect with virtually any service that Zapier supports.
#
# It is initialized with a webhook_url and payload data to send to Zapier.
# It returns the response body from Zapier to confirm the webhook was triggered successfully.
#
# Example usage: When you want to send AI-processed data to any service that Zapier supports,
# such as adding rows to Google Sheets, creating Trello cards, or sending emails.

class ZapierWebhookTriggerAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload:)
    @webhook_url = webhook_url
    @payload = payload
  end

  def call
    begin
      trigger_webhook
    rescue StandardError => e
      error_message = "Error triggering Zapier webhook: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def trigger_webhook
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = @payload.to_json

    response = http.request(request)

    case response.code.to_i
    when 200..299
      Sublayer.configuration.logger.log(:info, 'Successfully triggered Zapier webhook')
      JSON.parse(response.body)
    else
      error_message = "Failed to trigger Zapier webhook. HTTP Response Code: #{response.code}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end