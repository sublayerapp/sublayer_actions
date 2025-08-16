require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for triggering a webhook call to an external service.
# This action allows for integration with additional third-party services by sending a POST request to a specified webhook URL.
#
# It is initialized with a webhook_url and an optional payload (which can be a hash that will be sent as JSON).
# It returns the HTTP response code to confirm the webhook was triggered successfully.
#
# Example usage: When you want to notify an external service or application about an event triggered by an AI workflow.

class WebhookTriggerAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload: {})
    @webhook_url = webhook_url
    @payload = payload
  end

  def call
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = @payload.to_json

    begin
      response = http.request(request)
      case response.code.to_i
      when 200..299
        Sublayer.configuration.logger.log(:info, "Webhook triggered successfully. Response Code: \\#{response.code}")
        response.code.to_i
      else
        error_message = "Failed to trigger webhook. HTTP Response Code: \\#{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error triggering webhook: \\#{e.message}")
      raise e
    end
  end
end
