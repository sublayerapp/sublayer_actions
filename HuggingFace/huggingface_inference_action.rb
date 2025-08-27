require 'httparty'

# Description: Sublayer::Action responsible for making inference calls to deployed Hugging Face models.
# This action enables integration with custom or specialized AI models hosted on Hugging Face's inference API.
#
# Requires: 'httparty' gem
# $ gem install httparty
# Or add `gem 'httparty'` to your Gemfile
#
# It is initialized with a model_id and inputs, with optional parameters for the API call.
# It returns the model's inference results.
#
# Example usage: When you need specialized AI capabilities like:
# - Custom text classification
# - Image recognition with specific models
# - Token classification
# - Question answering with domain-specific models

class HuggingFaceInferenceAction < Sublayer::Actions::Base
  include HTTParty
  base_uri 'https://api-inference.huggingface.co/models'
  
  def initialize(model_id:, inputs:, parameters: {})
    @model_id = model_id
    @inputs = inputs
    @parameters = parameters
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
        body: {
          inputs: @inputs,
          parameters: @parameters
        }.to_json
      )

      case response.code
      when 200
        Sublayer.configuration.logger.log(:info, "Successfully made inference call to model: #{@model_id}")
        response.parsed_response
      when 429
        error_message = "Rate limit exceeded for Hugging Face API"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      when 404
        error_message = "Model '#{@model_id}' not found"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      else
        error_message = "Hugging Face API error: #{response.code} - #{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue HTTParty::Error => e
      error_message = "HTTP error during inference call: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error making inference call: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end