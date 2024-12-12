require 'net/http'
require 'json'

# Description: Sublayer::Action responsible for sending an HTTP request to a given URL.
# This action allows for interaction with various web services and APIs within a Sublayer workflow.
#
# It is initialized with a url, method, headers, and body.
# It returns the HTTP response body.
#
# Example usage: When you want to interact with an external API or web service from within your Sublayer workflow.

class HttpRequestAction < Sublayer::Actions::Base
  def initialize(url:, method: 'GET', headers: {}, body: nil)
    @url = URI.parse(url)
    @method = method.upcase
    @headers = headers
    @body = body
  end

  def call
    begin
      request = create_request
      add_headers(request)
      add_body(request)

      response = Net::HTTP.start(@url.host, @url.port, use_ssl: @url.scheme == 'https') do |http|
        http.request(request)
      end

      handle_response(response)
    rescue StandardError => e
      error_message = "Error making HTTP request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_request
    case @method
    when 'GET'
      Net::HTTP::Get.new(@url)
    when 'POST'
      Net::HTTP::Post.new(@url)
    when 'PUT'
      Net::HTTP::Put.new(@url)
    when 'DELETE'
      Net::HTTP::Delete.new(@url)
    when 'PATCH'
      Net::HTTP::Patch.new(@url)
    else
      raise StandardError, "Unsupported HTTP method: #{@method}"
    end
  end

  def add_headers(request)
    @headers.each do |key, value|
      request[key] = value
    end
  end

  def add_body(request)
    request.body = @body.to_json if @body
  end

  def handle_response(response)
    case response.code.to_i
    when 200..299
      Sublayer.configuration.logger.log(:info, "HTTP request successful: #{response.code}")
      JSON.parse(response.body) rescue response.body # Try to parse as JSON, fallback to raw body
    else
      error_message = "HTTP request failed: #{response.code} - #{response.body}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end