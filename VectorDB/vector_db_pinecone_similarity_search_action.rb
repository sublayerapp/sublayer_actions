require 'pinecone'

# Description: Sublayer::Action responsible for retrieving the top N most similar documents from a Pinecone vector database.
# This action is intended for use in Retrieval Augmented Generation (RAG) applications or semantic search scenarios.
#
# It is initialized with a Pinecone index name, query text or vector, and the number of results to return (top_k).
# It returns an array of the top_k most similar documents from the index, along with their similarity scores.
#
# Example usage: When you want to augment an LLM prompt with context retrieved from a vector database based on semantic similarity.

class VectorDBPineconeSimilaritySearchAction < Sublayer::Actions::Base
  def initialize(index_name:, query:, top_k: 10, api_key: nil, environment: nil)
    @index_name = index_name
    @query = query
    @top_k = top_k
    @api_key = api_key || ENV['PINECONE_API_KEY']
    @environment = environment || ENV['PINECONE_ENVIRONMENT']
  end

  def call
    Pinecone.configure do |config|
      config.api_key = @api_key
      config.environment = @environment
    end

    index = Pinecone::Index.new(@index_name)

    begin
      # Check if the query is a vector or text and handle accordingly
      if @query.is_a?(Array)
        query_vector = @query
        response = index.query(
          vector: query_vector,
          top_k: @top_k,
          include_values: false,
          include_metadata: true
        )
      else
        # For text-based queries, you'd typically use an embedding model
        # to convert the text into a vector before querying Pinecone.
        # This example assumes you have an embedding model available.
        # Replace the following lines with your embedding logic.
        # Example:
        # embedding_model = OpenAIEmbeddingModel.new
        # query_vector = embedding_model.embed(@query)
        raise StandardError, "Text-based queries require an embedding model to convert text to vectors.  Please pass in vector instead."
      end

      matches = response.matches

      Sublayer.configuration.logger.log(:info, "Successfully retrieved #{@top_k} similar documents from Pinecone index \#{@index_name}")

      matches.map { |match| { id: match.id, score: match.score, metadata: match.metadata } }
    rescue Pinecone::Error => e
      error_message = "Error querying Pinecone index \#{@index_name}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error during vector DB similarity search: #{e.message}")
      raise e
    end
  end
end