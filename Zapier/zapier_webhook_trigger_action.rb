require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for triggering a Zapier webhook with custom data.
# This action enables integration with Zapier's automation platform, allowing Sublayer
# to connect with thousands of other services through Zapier's workflows (Zaps).
#
# It is initialized with a webhook_url and data to send to the webhook.
# It returns the HTTP response code to confirm the webhook was triggered successfully.
#
# Example usage: When you want to send AI-generated data or analysis results to other
# services through Zapier automations.

class ZapierWebhookTriggerAction < Sublayer::Actions::Base
  def initialize(webhook_url:, data:)
    @webhook_url = webhook_url
    @data = data
  end

  def call
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = @data.to_json

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
    rescue StandardError => e
      error_message = "Error triggering Zapier webhook: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end