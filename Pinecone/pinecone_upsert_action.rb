require 'pinecone'

# Description: Sublayer::Action responsible for upserting vector embeddings and metadata to a Pinecone vector database.
# This action enables easy management of vector embeddings for semantic search and similarity matching use cases.
#
# Requires: 'pinecone-client' gem
# $ gem install pinecone-client
# Or add `gem 'pinecone-client'` to your Gemfile
#
# It is initialized with vectors (array of vectors), namespace (optional), and metadata (optional).
# Each vector should be a hash containing 'id', 'values', and optionally 'metadata'.
# It returns the Pinecone API response confirming the upsert operation.
#
# Example usage: When you want to store vector embeddings (like from OpenAI embeddings API)
# in a Pinecone database for later similarity search or semantic matching.

class PineconeUpsertAction < Sublayer::Actions::Base
  def initialize(vectors:, namespace: nil)
    @vectors = vectors
    @namespace = namespace
    @index_name = ENV['PINECONE_INDEX_NAME']
    
    Pinecone.configure do |config|
      config.api_key = ENV['PINECONE_API_KEY']
      config.environment = ENV['PINECONE_ENVIRONMENT']
    end
  end

  def call
    begin
      validate_vectors
      perform_upsert
    rescue ArgumentError => e
      error_message = "Invalid vector format: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Pinecone::Error => e
      error_message = "Pinecone API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error upserting vectors: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_vectors
    @vectors.each do |vector|
      unless vector.key?('id') && vector.key?('values')
        raise ArgumentError, "Each vector must contain 'id' and 'values' keys"
      end
      
      unless vector['values'].is_a?(Array)
        raise ArgumentError, "Vector values must be an array of numbers"
      end
    end
  end

  def perform_upsert
    index = Pinecone::Index.new(name: @index_name)
    
    response = if @namespace
      index.upsert(vectors: @vectors, namespace: @namespace)
    else
      index.upsert(vectors: @vectors)
    end

    Sublayer.configuration.logger.log(:info, "Successfully upserted #{@vectors.length} vectors to Pinecone index #{@index_name}")
    response
  end
end