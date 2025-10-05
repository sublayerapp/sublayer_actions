require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for triggering a Zap in Zapier.
# It sends a POST request to a Zapier webhook URL with provided input data.
#
# It is initialized with a webhook_url and a data payload (a hash).
# It returns the HTTP response code from Zapier to confirm the Zap was triggered successfully.
#
# Example usage: When you want to connect a Sublayer workflow to a wide variety of third-party services via Zapier.

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
        Sublayer.configuration.logger.log(:info, "Zap triggered successfully via Zapier webhook")
        response.code.to_i
      else
        error_message = "Failed to trigger Zap. HTTP Response Code: #{response.code}, Body: #{response.body}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error triggering Zap: #{e.message}")
      raise e
    end
  end
end
