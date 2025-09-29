require 'pinecone'

# Description: Sublayer::Action responsible for upserting a vector into a Pinecone index.
# This action allows for storing vector embeddings in Pinecone for semantic search and RAG.
#
# It is initialized with index_name, id, vector, and optional metadata.
# It returns the id of the upserted vector.
#
# Example usage: When you want to store vector embeddings of text or images in Pinecone for semantic search.

class PineconeUpsertVectorAction < Sublayer::Actions::Base
  def initialize(index_name:, id:, vector:, metadata: {})
    @index_name = index_name
    @id = id
    @vector = vector
    @metadata = metadata
    Pinecone.configure do |config|
      config.api_key = ENV['PINECONE_API_KEY']
      config.environment = ENV['PINECONE_ENVIRONMENT'] # Example: 'us-west1-gcp'
    end
    @index = Pinecone::Index.new(@index_name)
  end

  def call
    begin
      upsert_response = @index.upsert(
        vectors: [
          {
            id: @id,
            values: @vector,
            metadata: @metadata
          }
        ]
      )
      
      Sublayer.configuration.logger.log(:info, "Vector upserted successfully to Pinecone index \#{@index_name} with ID: \#{@id}")
      @id # Return the ID of the upserted vector
    rescue Pinecone::ApiError => e
      error_message = "Error upserting vector to Pinecone: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error upserting vector to Pinecone: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end