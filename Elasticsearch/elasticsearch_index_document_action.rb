require 'elasticsearch'

# Description: Sublayer::Action responsible for indexing a document in Elasticsearch.
# This action allows for easy integration of document indexing into Sublayer workflows,
# making AI-generated or processed content searchable and analyzable.
#
# Requires: 'elasticsearch' gem
# $ gem install elasticsearch
# Or add `gem 'elasticsearch'` to your Gemfile
#
# It is initialized with an index name, document ID, and the document body to be indexed.
# It returns the Elasticsearch response, which includes metadata about the indexing operation.
#
# Example usage: When you want to make AI-generated content searchable by indexing it in Elasticsearch.

class ElasticsearchIndexDocumentAction < Sublayer::Actions::Base
  def initialize(index:, id:, body:, host: 'localhost', port: 9200)
    @index = index
    @id = id
    @body = body
    @client = Elasticsearch::Client.new(host: host, port: port)
  end

  def call
    begin
      response = @client.index(
        index: @index,
        id: @id,
        body: @body
      )
      
      Sublayer.configuration.logger.log(:info, "Document indexed successfully in Elasticsearch. Index: #{@index}, ID: #{@id}")
      response
    rescue Elasticsearch::Transport::Transport::Errors::NotFound => e
      error_message = "Index not found: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Elasticsearch::Transport::Transport::Error => e
      error_message = "Error indexing document in Elasticsearch: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end