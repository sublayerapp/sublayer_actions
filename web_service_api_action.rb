require 'net/http'
require 'json'

module Sublayer
  module Actions
    class WebServiceApiAction < Sublayer::Actions::Base
      def initialize(params)
        super(params)
        @api_url = params['api_url']
        @http_method = (params['http_method'] || 'GET').upcase
        @headers = params['headers'] || {}
        @body = params['body']
      end

      def call
        response = make_request

        case response.code.to_i
        when 200..299
          logger.info "Successfully called #{@api_url}"
          return JSON.parse(response.body) if response.body.present?
          return { message: 'Success' }
        else
          logger.error "Error calling #{@api_url}: #{response.code} - #{response.body}"
          raise "Error calling #{@api_url}: #{response.code} - #{response.body}"
        end
      rescue StandardError => e
        logger.error "Error in WebServiceApiAction: #{e.message}"
        raise
      end

      private

      def make_request
        uri = URI(@api_url)
        request = Net::HTTP.const_get(@http_method).new(uri)
        @headers.each { |key, value| request[key] = value }
        request.body = @body.to_json if @body
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
      end
    end
  end
end