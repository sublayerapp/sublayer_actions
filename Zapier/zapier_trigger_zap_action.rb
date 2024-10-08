require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for triggering a Zap in Zapier.
# This action allows Sublayer to interact with Zapier, triggering Zaps based on specific events or data.
#
# It is initialized with the Zapier webhook URL and a hash of data to be sent to the Zap.
# It returns the HTTP response code to confirm the Zap was triggered successfully.
#
# Example usage: When you want to trigger a Zap based on an event or data generated within a Sublayer workflow.

class ZapierTriggerZapAction < Sublayer::Actions::Base
  def initialize(webhook_url:, data: {})
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
        Sublayer.configuration.logger.log(:info, "Zap triggered successfully with data: #{@data}")
        response.code.to_i
      else
        error_message = "Failed to trigger Zap. HTTP Response Code: #{response.code}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error triggering Zap: #{e.message}")
      raise e
    end
  end
end
