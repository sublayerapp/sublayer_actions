require 'net/http'
require 'uri'

module Sublayer
  module Actions
    class RetrieveWebpageContentAction < Sublayer::Actions::Base
      def initialize(url:)
        @url = url
      end

      def call
        response = Net::HTTP.get_response(URI.parse(@url))

        case response
        when Net::HTTPSuccess
          response.body
        else
          logger.error "Failed to retrieve webpage content from #{@url}. Status code: #{response.code}"
          raise "Failed to retrieve webpage content"
        end
      rescue StandardError => e
        logger.error "Error retrieving webpage content: #{e.message}"
        raise
      end
    end
  end
end