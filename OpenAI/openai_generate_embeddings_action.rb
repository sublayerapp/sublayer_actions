require 'openai'

# Description: Sublayer::Action responsible for generating embeddings from text using OpenAI's embeddings API.
# This action provides a simple interface for converting text into vector representations that can be used
# for semantic search, document similarity comparisons, and other NLP tasks.
#
# It is initialized with text content and optionally the model to use for embeddings.
# It returns the embedding vector as an array of floats.
#
# Example usage: When you want to generate embeddings for text content to use in semantic search
# or document comparison operations.

class OpenAIGenerateEmbeddingsAction < Sublayer::Actions::Base
  def initialize(text:, model: 'text-embedding-ada-002')
    @text = text
    @model = model
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      response = @client.embeddings(
        parameters: {
          model: @model,
          input: @text
        }
      )

      embedding = response['data'][0]['embedding']
      
      Sublayer.configuration.logger.log(:info, "Generated embedding vector of size #{embedding.size}")
      
      embedding
    rescue OpenAI::Error => e
      error_message = "Error generating embeddings: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error generating embeddings: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end