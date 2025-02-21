require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for sending a webhook trigger to a specified URL.
# This action is useful for triggering other services or actions to start based on Sublayer outputs.
#
# Example usage: When you want to initiate a chain reaction of processes in different systems as part of a Sublayer workflow.

class WebhookTriggerAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload: {}, headers: {})
    @webhook_url = webhook_url
    @payload = payload
    @headers = headers
  end

  def call
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')

    request = Net::HTTP::Post.new(uri.request_uri, @headers)
    request.content_type = 'application/json'
    request.body = @payload.to_json

    begin
      response = http.request(request)
      case response.code.to_i
      when 200..299
        Sublayer.configuration.logger.log(:info, "Webhook triggered successfully. URL: #{@webhook_url}")
        response.code.to_i
      else
        error_message = "Failed to trigger webhook. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error triggering webhook: #{e.message}")
      raise e
    end
  end
end
