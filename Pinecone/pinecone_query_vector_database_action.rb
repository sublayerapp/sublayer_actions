require 'pinecone'

# Description: Sublayer::Action responsible for querying a Pinecone vector database with an embedding vector.
# Returns the top matching documents for semantic search and retrieval-augmented generation (RAG).
#
# It is initialized with a pinecone_index_name, embedding_vector, top_k (number of results to return), and optionally namespace.
# It returns an array of the top_k matching documents with their scores.
#
# Example usage: When you want to perform semantic search on a Pinecone vector database to retrieve relevant documents based on a query embedding.

class PineconeQueryVectorDatabaseAction < Sublayer::Actions::Base
  def initialize(pinecone_index_name:, embedding_vector:, top_k: 10, namespace: nil)
    @pinecone_index_name = pinecone_index_name
    @embedding_vector = embedding_vector
    @top_k = top_k
    @namespace = namespace
    Pinecone.configure do |config|
      config.api_key = ENV['PINECONE_API_KEY']
      config.environment = ENV['PINECONE_ENVIRONMENT'] # e.g., 'us-west1-gcp'
    end
    @index = Pinecone::Index.new(@pinecone_index_name)
  end

  def call
    begin
      query_options = {
        vector: @embedding_vector,
        top_k: @top_k,
        include_values: false, # Set to true if you need the vectors in the response
        include_metadata: true  # Set to true if you need the metadata in the response
      }

      query_options[:namespace] = @namespace if @namespace

      response = @index.query(query_options)
      matches = response.matches

      Sublayer.configuration.logger.log(:info, "Successfully queried Pinecone index \#{@pinecone_index_name} and retrieved \#{matches.size} matches.")

      matches.map { |match| { id: match.id, score: match.score, metadata: match.metadata } }
    rescue Pinecone::Error => e
      error_message = "Error querying Pinecone database: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during Pinecone query: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end