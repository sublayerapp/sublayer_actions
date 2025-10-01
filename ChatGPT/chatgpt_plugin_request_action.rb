require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for making requests to ChatGPT Plugin API endpoints.
# This action handles authentication and response parsing for ChatGPT plugins, allowing Sublayer
# to integrate with the growing ecosystem of specialized tools and services available through
# the ChatGPT plugin system.
#
# It is initialized with the plugin's base URL, endpoint path, and optional parameters.
# It returns the parsed response from the plugin API.
#
# Example usage: When you want to interact with a ChatGPT plugin's API to access specialized
# functionality or data within your Sublayer workflow.
#
# Required Environment Variables:
# - CHATGPT_PLUGIN_API_KEY: API key for the ChatGPT plugin (if required)

class ChatGPTPluginRequestAction < Sublayer::Actions::Base
  def initialize(base_url:, endpoint:, method: 'GET', params: {}, headers: {})
    @base_url = base_url.chomp('/')
    @endpoint = endpoint.start_with?('/') ? endpoint : "/#{endpoint}"
    @method = method.upcase
    @params = params
    @headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{ENV['CHATGPT_PLUGIN_API_KEY']}"
    }.merge(headers)
  end

  def call
    begin
      response = make_request
      handle_response(response)
    rescue StandardError => e
      handle_error(e)
    end
  end

  private

  def make_request
    uri = URI.parse("#{@base_url}#{@endpoint}")
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    case @method
    when 'GET'
      uri.query = URI.encode_www_form(@params) unless @params.empty?
      request = Net::HTTP::Get.new(uri.request_uri)
    when 'POST'
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = @params.to_json
    when 'PUT'
      request = Net::HTTP::Put.new(uri.request_uri)
      request.body = @params.to_json
    when 'DELETE'
      request = Net::HTTP::Delete.new(uri.request_uri)
    else
      raise ArgumentError, "Unsupported HTTP method: #{@method}"
    end

    @headers.each { |key, value| request[key] = value }
    http.request(request)
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      begin
        parsed_response = JSON.parse(response.body)
        Sublayer.configuration.logger.log(:info, 
          "Successfully made request to ChatGPT plugin: #{@base_url}#{@endpoint}")
        parsed_response
      rescue JSON::ParserError => e
        error_message = "Failed to parse JSON response: #{e.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    else
      error_message = "Plugin API request failed: #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def handle_error(error)
    error_message = "Error making ChatGPT plugin request: #{error.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise error
  end
end