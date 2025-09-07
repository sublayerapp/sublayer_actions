require 'net/http'
require 'json'

# Description: Sublayer::Action responsible for triggering a Zap on Zapier.
# This action allows for integration with Zapier, enabling Sublayer workflows to interact with a multitude of services supported by Zapier.
#
# It is initialized with a webhook_url and optionally, a payload to send to the Zap. It returns a response status to confirm the Zap was triggered successfully.
#
# Example usage: When you want to trigger a workflow in Zapier from a Sublayer process when certain conditions are met.

class ZapierTriggerAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload: {})
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
        Sublayer.configuration.logger.log(:info, "Zap triggered successfully")
        response.code.to_i
      else
        error_message = "Failed to trigger Zap. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error triggering Zapier Zap: #{e.message}")
      raise e
    end
  end
end