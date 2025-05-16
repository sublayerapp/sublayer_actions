require 'elasticsearch'

# Description: Sublayer::Action responsible for querying an Elasticsearch index.
# This action allows you to execute a custom search query against Elasticsearch and retrieve the results.
#
# It is initialized with an Elasticsearch index, query, and optional client configuration.
# It returns an array of hits from the Elasticsearch query.
#
# Example usage: When you need to retrieve structured data from Elasticsearch for analysis or decision-making in a Sublayer workflow.

class ElasticsearchQueryAction < Sublayer::Actions::Base
  def initialize(index:, query:, client_options: {})
    @index = index
    @query = query
    @client_options = client_options
    @client = Elasticsearch::Client.new(@client_options.merge(log: true))
  end

  def call
    begin
      response = @client.search(index: @index, body: @query)
      hits = response['hits']['hits']

      Sublayer.configuration.logger.log(:info, "Successfully queried Elasticsearch index \#{@index}")

      hits
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
      error_message = "Elasticsearch index not found: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Elasticsearch::Transport::Transport::Errors::BadRequest => e
      error_message = "Invalid Elasticsearch query: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error querying Elasticsearch: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end