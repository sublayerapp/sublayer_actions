require 'pinecone'

# Description: Sublayer::Action responsible for upserting text and vector embeddings into a Pinecone vector database.
# This action enables storing and managing vector embeddings for semantic search and AI applications.
#
# Requires: 'pinecone' gem
# $ gem install pinecone
# Or add `gem 'pinecone'` to your Gemfile
#
# It is initialized with the index_name, text content, vector embedding, and an optional namespace and metadata.
# It returns the ID of the upserted vector.
#
# Example usage: When you want to store vector embeddings of documents or text content
# for later semantic search or similarity matching in AI applications.

class PineconeUpsertEmbeddingAction < Sublayer::Actions::Base
  def initialize(index_name:, text:, vector:, namespace: '', metadata: {})
    @index_name = index_name
    @text = text
    @vector = vector
    @namespace = namespace
    @metadata = metadata
    @client = Pinecone::Client.new(
      api_key: ENV['PINECONE_API_KEY'],
      environment: ENV['PINECONE_ENVIRONMENT']
    )
  end

  def call
    begin
      # Generate a unique ID for the vector
      vector_id = generate_vector_id

      # Add the text content to metadata for potential retrieval
      full_metadata = @metadata.merge({
        text_content: @text,
        timestamp: Time.now.to_i
      })

      # Get the specified index
      index = @client.index(@index_name)

      # Perform the upsert operation
      response = index.upsert(
        vectors: [{
          id: vector_id,
          values: @vector,
          metadata: full_metadata
        }],
        namespace: @namespace
      )

      Sublayer.configuration.logger.log(:info, "Successfully upserted vector with ID: #{vector_id} to Pinecone index: #{@index_name}")
      vector_id

    rescue Pinecone::Error => e
      error_message = "Pinecone upsert error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error upserting to Pinecone: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def generate_vector_id
    # Generate a unique ID combining timestamp and random string
    timestamp = Time.now.to_i
    random_string = SecureRandom.hex(4)
    "vec_#{timestamp}_#{random_string}"
  end
end