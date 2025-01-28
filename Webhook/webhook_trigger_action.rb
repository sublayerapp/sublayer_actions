class WebhookTriggerAction < Sublayer::Actions::Base
  require 'net/http'
  require 'uri'

  # Initialize with the webhook URL and optional headers and payload
  def initialize(webhook_url:, payload: {}, headers: {})
    @webhook_url = webhook_url
    @payload = payload
    @headers = headers
  end

  # Trigger the webhook
  def call
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri.request_uri, @headers)
    request.body = @payload.to_json

    begin
      response = http.request(request)
      case response.code.to_i
      when 200..299
        Sublayer.configuration.logger.log(:info, "Webhook triggered successfully, HTTP Response Code: #{response.code}")
        response.body
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
