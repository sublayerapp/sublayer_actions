require 'cohere'

# Description: Sublayer::Action responsible for generating embeddings from text using Cohere's API.
# This action enables semantic search and text similarity capabilities in AI workflows.
#
# Requires: 'cohere-ruby' gem
# $ gem install cohere-ruby
# Or add `gem 'cohere-ruby'` to your Gemfile
#
# It is initialized with text content and optional model parameters.
# It returns a vector embedding of the input text that can be used for semantic search or similarity comparisons.
#
# Example usage: When you want to create embeddings for text to enable semantic search or
# calculate similarity between different pieces of text in your AI workflow.

class CohereEmbeddingAction < Sublayer::Actions::Base
  def initialize(text:, model: 'embed-english-v3.0')
    @text = text
    @model = model
    @client = Cohere::Client.new(api_key: ENV['COHERE_API_KEY'])
  end

  def call
    begin
      validate_input
      response = generate_embedding
      
      Sublayer.configuration.logger.log(:info, 'Successfully generated embedding from text')
      response.embeddings.first
    rescue Cohere::Error => e
      error_message = "Cohere API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error generating embedding: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_input
    raise StandardError, 'Text input cannot be empty' if @text.to_s.strip.empty?
  end

  def generate_embedding
    @client.embed(
      texts: [@text],
      model: @model,
      input_type: 'search_document'
    )
  end
end