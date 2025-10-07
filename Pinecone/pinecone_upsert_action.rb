require 'pinecone'
require 'openai'

# Description: Sublayer::Action responsible for upserting text content into a Pinecone vector database.
# The action handles the conversion of text to embeddings using OpenAI's embedding model and
# stores these embeddings in Pinecone for vector search capabilities.
#
# Requires: 'pinecone' and 'openai' gems
# $ gem install pinecone openai
# Or add to your Gemfile:
# gem 'pinecone'
# gem 'openai'
#
# It is initialized with the text content to embed, an optional metadata hash, and an optional ID.
# If no ID is provided, a UUID will be generated.
#
# Example usage: When you want to store AI-generated content or source materials in a vector database
# for semantic search and retrieval.

class PineconeUpsertAction < Sublayer::Actions::Base
  def initialize(content:, metadata: {}, id: nil, index_name: nil)
    @content = content
    @metadata = metadata
    @id = id || SecureRandom.uuid
    @index_name = index_name || ENV['PINECONE_INDEX_NAME']
    
    @openai_client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    
    Pinecone.configure do |config|
      config.api_key = ENV['PINECONE_API_KEY']
      config.environment = ENV['PINECONE_ENVIRONMENT']
    end
    
    @pinecone_client = Pinecone::Client.new
  end

  def call
    begin
      # Get embeddings from OpenAI
      embeddings = generate_embeddings
      
      # Prepare vector for Pinecone
      vector = {
        id: @id,
        values: embeddings,
        metadata: @metadata.merge({
          content: @content,
          timestamp: Time.now.utc.iso8601
        })
      }
      
      # Upsert to Pinecone
      index = @pinecone_client.index(@index_name)
      response = index.upsert(vectors: [vector])
      
      Sublayer.configuration.logger.log(:info, "Successfully upserted vector with ID: #{@id}")
      
      @id
    rescue OpenAI::Error => e
      error_message = "Error generating embeddings: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Pinecone::Error => e
      error_message = "Error upserting to Pinecone: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def generate_embeddings
    response = @openai_client.embeddings(
      parameters: {
        model: 'text-embedding-ada-002',
        input: @content
      }
    )

    response['data'][0]['embedding']
  end
end