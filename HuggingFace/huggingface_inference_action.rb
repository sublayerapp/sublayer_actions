require 'httparty'

# Description: Sublayer::Action responsible for running inference on Hugging Face models via their Inference API.
# This action enables integration with open-source AI models hosted on Hugging Face for specialized tasks
# that complement LLM capabilities (e.g., text classification, token classification, image classification).
#
# Requires: 'httparty' gem
# $ gem install httparty
# Or add `gem 'httparty'` to your Gemfile
#
# It is initialized with a model_id and inputs for the model.
# It returns the model's inference results.
#
# Example usage: When you want to use specialized AI models for tasks like:
# - Sentiment analysis
# - Named Entity Recognition
# - Image classification
# - Text classification
# - And other tasks where specialized models might perform better than general-purpose LLMs

class HuggingFaceInferenceAction < Sublayer::Actions::Base
  include HTTParty
  base_uri 'https://api-inference.huggingface.co/models'
  
  def initialize(model_id:, inputs:)
    @model_id = model_id
    @inputs = inputs
    @api_token = ENV['HUGGINGFACE_API_TOKEN']
    
    raise ArgumentError, 'HUGGINGFACE_API_TOKEN environment variable is not set' unless @api_token
  end

  def call
    begin
      response = self.class.post(
        "/#{@model_id}",
        headers: {
          'Authorization' => "Bearer #{@api_token}",
          'Content-Type' => 'application/json'
        },
        body: { inputs: @inputs }.to_json
      )

      case response.code
      when 200
        Sublayer.configuration.logger.log(:info, "Successfully ran inference on model #{@model_id}")
        JSON.parse(response.body)
      when 503
        error_message = "Model is loading. Please retry after a few seconds."
        Sublayer.configuration.logger.log(:warn, error_message)
        raise StandardError, error_message
      else
        error_message = "Error running inference: HTTP #{response.code} - #{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue JSON::ParserError => e
      error_message = "Error parsing response: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue HTTParty::Error => e
      error_message = "HTTP error during inference: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error running Hugging Face inference: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end