require 'pinecone'

# Description: Sublayer::Action responsible for querying a Pinecone vector database.
# It finds the most similar vectors to a given input vector.
#
# It is initialized with a pinecone_index_name, vector, and optionally top_k (number of results to return).
# It returns an array of the top_k most similar vectors with their scores.
#
# Example usage: When you want to perform semantic search or retrieve related information
# from a Pinecone database based on a vector representation of a query.

class PineconeQueryVectorAction < Sublayer::Actions::Base
  def initialize(pinecone_index_name:, vector:, top_k: 10)
    @pinecone_index_name = pinecone_index_name
    @vector = vector
    @top_k = top_k
    Pinecone.configure do |config|
      config.api_key = ENV['PINECONE_API_KEY']
      config.environment = ENV['PINECONE_ENVIRONMENT'] # Example: 'us-east4-gcp'
    end
    @index = Pinecone::Index.new(@pinecone_index_name)
  end

  def call
    begin
      query_response = @index.query(
        vector: @vector,
        top_k: @top_k,
        include_values: false,
        include_metadata: false
      )

      results = query_response.matches.map { |match| { id: match.id, score: match.score } }

      Sublayer.configuration.logger.log(:info, "Successfully queried Pinecone index \"#{@pinecone_index_name}\"")
      results
    rescue Pinecone::Error => e
      error_message = "Error querying Pinecone: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during Pinecone query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end