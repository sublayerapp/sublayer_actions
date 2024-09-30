require 'net/http'
require 'uri'
require 'json'

module Sublayer
  module Actions
    class ApiRequestAction < Sublayer::Actions::Base
      def initialize(config)
        super
        @base_url = config[:base_url]
        @headers = config[:headers] || {}
        @auth_type = config[:auth_type]
        @auth_token = config[:auth_token]
        @timeout = config[:timeout] || 30
      end

      def call(method:, endpoint:, params: {}, body: nil)
        url = build_url(endpoint, params)
        request = build_request(method, url, body)
        add_auth_header(request) if @auth_type && @auth_token

        begin
          response = send_request(request)
          handle_response(response)
        rescue StandardError => e
          log_error(e)
          raise Sublayer::Actions::ActionError, "API request failed: #{e.message}"
        end
      end

      private

      def build_url(endpoint, params)
        uri = URI.join(@base_url, endpoint)
        uri.query = URI.encode_www_form(params) unless params.empty?
        uri
      end

      def build_request(method, url, body)
        request_class = case method.to_s.upcase
                        when 'GET' then Net::HTTP::Get
                        when 'POST' then Net::HTTP::Post
                        when 'PUT' then Net::HTTP::Put
                        when 'DELETE' then Net::HTTP::Delete
                        else
                          raise ArgumentError, "Unsupported HTTP method: #{method}"
                        end

        request = request_class.new(url)
        @headers.each { |key, value| request[key] = value }
        request.body = body.to_json if body
        request['Content-Type'] = 'application/json' if body
        request
      end

      def add_auth_header(request)
        case @auth_type.to_s.downcase
        when 'bearer'
          request['Authorization'] = "Bearer #{@auth_token}"
        when 'basic'
          request['Authorization'] = "Basic #{Base64.strict_encode64(@auth_token)}"
        when 'api_key'
          request['X-API-Key'] = @auth_token
        else
          raise ArgumentError, "Unsupported auth type: #{@auth_type}"
        end
      end

      def send_request(request)
        Net::HTTP.start(request.uri.hostname, request.uri.port, use_ssl: request.uri.scheme == 'https') do |http|
          http.read_timeout = @timeout
          http.request(request)
        end
      end

      def handle_response(response)
        case response
        when Net::HTTPSuccess
          parse_json_response(response)
        else
          raise Sublayer::Actions::ActionError, "HTTP request failed with status #{response.code}: #{response.message}"
        end
      end

      def parse_json_response(response)
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        log_error(e)
        raise Sublayer::Actions::ActionError, "Failed to parse JSON response: #{e.message}"
      end

      def log_error(error)
        Sublayer.logger.error("ApiRequestAction error: #{error.class} - #{error.message}")
        Sublayer.logger.error(error.backtrace.join("\n"))
      end
    end
  end
end