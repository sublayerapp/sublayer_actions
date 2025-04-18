require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for triggering a Zap on Zapier.
# This action enables integration with Zapier, which allows automation across various apps and services.
#
# It is initialized with a zap_url and optional parameters to pass to the Zap.
# It returns the HTTP response code to confirm the trigger was successful.
#
# Example usage: When you want to automate a process involving multiple different services via a Zapier workflow.

class ZapierTriggerAction < Sublayer::Actions::Base
  def initialize(zap_url:, payload: {})
    @zap_url = zap_url
    @payload = payload
  end

  def call
    uri = URI.parse(@zap_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.request_uri)
    request.content_type = 'application/json'
    request.body = @payload.to_json

    begin
      response = http.request(request)
      handle_response(response)
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error triggering Zapier Zap: #{e.message}")
      raise e
    end
  end

  private

  def handle_response(response)
    case response.code.to_i
    when 200..299
      Sublayer.configuration.logger.log(:info, "Zap triggered successfully with response code: #{response.code}")
      response.code.to_i
    else
      error_message = "Failed to trigger Zap. HTTP Response Code: #{response.code}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end