# Description: Sublayer::Action responsible for triggering a Zapier workflow.
# This action can be used to integrate with many apps and automate tasks seamlessly
# by triggering Zaps in Zapier.
#
# It is initialized with a webhook_url that is specific to the Zap you wish to trigger.
#
# Example usage: Automate the creation of a task in Asana when something happens in another application.

require 'net/http'
require 'uri'
require 'json'

class ZapierTriggerAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload: {})
    @webhook_url = webhook_url
    @payload = payload
  end

  def call
    uri = URI.parse(@webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
    request.body = @payload.to_json

    begin
      response = http.request(request)
      if response.is_a?(Net::HTTPSuccess)
        Sublayer.configuration.logger.log(:info, "Successfully triggered Zap at #{@webhook_url}")
        return true
      else
        Sublayer.configuration.logger.log(:error, "Failed to trigger Zap: #{response.body}")
        return false
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Exception occurred while triggering Zap: #{e.message}")
      raise e
    end
  end
end
