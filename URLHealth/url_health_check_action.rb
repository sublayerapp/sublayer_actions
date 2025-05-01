require 'net/http'
require 'uri'

# Description: Sublayer::Action responsible for checking the health of a URL.
# This action performs an HTTP request to the specified URL and evaluates the response.
# Useful for monitoring service endpoints integrated with Sublayer tasks.
#
# Example usage: When you want to monitor the availability of an API endpoint used in your Sublayer workflow.

class URLHealthCheckAction < Sublayer::Actions::Base
  def initialize(url:, timeout: 5)
    @url = url
    @timeout = timeout
  end

  def call
    check_url_health
  rescue StandardError => e
    error_message = "Error checking URL health: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def check_url_health
    uri = URI.parse(@url)
    response = nil

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', read_timeout: @timeout) do |http|
      request = Net::HTTP::Get.new(uri)
      response = http.request(request)
    end

    evaluate_response(response)
  end

  def evaluate_response(response)
    case response
    when Net::HTTPSuccess
      Sublayer.configuration.logger.log(:info, "URL #{@url} is healthy. HTTP Status: #{response.code}")
      { status: 'healthy', http_status: response.code }
    else
      error_message = "URL #{@url} is not healthy. HTTP Status: #{response.code}"
      Sublayer.configuration.logger.log(:error, error_message)
      { status: 'unhealthy', http_status: response.code, error: error_message }
    end
  end
end
