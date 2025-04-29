require 'google/apis/customsearch_v1'

# Description: Sublayer::Action for performing Google searches using the Custom Search JSON API.
# Useful for gathering information or context within workflows.

# Example Usage:
#   search_action = GoogleSearchAction.new(query: "Sublayer AI", cx: "YOUR_CUSTOM_SEARCH_ENGINE_ID", num: 10, api_key: ENV['GOOGLE_API_KEY'])
#   results = search_action.call

class GoogleSearchAction < Sublayer::Actions::Base
  def initialize(query:, cx:, num: 10, api_key: ENV['GOOGLE_API_KEY'])
    @query = query
    @cx = cx
    @num = num
    @api_key = api_key

    @service = Google::Apis::CustomsearchV1::CustomsearchService.new
    @service.key = @api_key
  end

  def call
    begin
      results = @service.list_cse_searches(q: @query, cx: @cx, num: @num)
      Sublayer.configuration.logger.log(:info, "Google Search successful for query: #{@query}")
      results.items
    rescue Google::Apis::ClientError => e
      error_message = "Error performing Google Search: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end