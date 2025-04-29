require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action to send an HTTP request to a given URL.
# This action enables Sublayer to interact with various APIs and web services directly,
# fetching data or triggering actions based on the HTTP response.
#
# It is initialized with a `url`, `method` (defaults to 'GET'), `headers` (optional),
# and `body` (optional, and should be a JSON string).
# It returns the parsed JSON response body if the request is successful and the response is JSON; otherwise,
# returns the raw response body as a string.
#
# Example usage: When you want to fetch data from an external API or trigger an action
# in a web service as part of your Sublayer workflow.

class HttpRequestAction < Sublayer::Actions::Base
  def initialize(url:, method: 'GET', headers: {}, body: nil)
    @url = url
    @method = method.upcase
    @headers = headers
    @body = body
  end

  def call
    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = case @method
              when 'GET'
                Net::HTTP::Get.new(uri)
              when 'POST'
                Net::HTTP::Post.new(uri)
              when 'PUT'
                Net::HTTP::Put.new(uri)
              when 'DELETE'
                Net::HTTP::Delete.new(uri)
              when 'PATCH'
                Net::HTTP::Patch.new(uri)  
              else
                raise ArgumentError, "Invalid HTTP method: #{@method}"
              end

    @headers.each { |key, value| request[key] = value }
    request.body = @body if @body

    begin
      response = http.request(request)

      case response.code.to_i
      when 200..299
        Sublayer.configuration.logger.log(:info, "HTTP request successful: #{@url}")
        begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          response.body
        end
      else
        error_message = "HTTP request failed (#{response.code}): #{@url} - #{response.body}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error during HTTP request: #{e.message}")
      raise e
    end
  end
end