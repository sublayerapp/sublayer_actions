require 'httparty'

# Description: Sublayer::Action responsible for making inference requests to HuggingFace model endpoints.
# This action enables integration with open source models hosted on HuggingFace,
# expanding model options beyond OpenAI, Claude, and Gemini.
#
# Requires: 'httparty' gem
# $ gem install httparty
# Or add `gem 'httparty'` to your Gemfile
#
# It is initialized with:
# - model_id: The HuggingFace model ID (e.g., 'gpt2', 'bert-base-uncased')
# - inputs: The input text or data for the model
# - parameters: Optional parameters specific to the model (temperature, max_length, etc.)
#
# Returns the model's inference response.
#
# Example usage: When you want to use a specific open source model from HuggingFace
# for text generation, classification, or other ML tasks within your Sublayer workflow.

class HuggingFaceInferenceAction < Sublayer::Actions::Base
  include HTTParty
  base_uri 'https://api-inference.huggingface.co/models'
  
  def initialize(model_id:, inputs:, parameters: {})
    @model_id = model_id
    @inputs = inputs
    @parameters = parameters
    @api_token = ENV['HUGGINGFACE_API_TOKEN']
    
    raise ArgumentError, 'HUGGINGFACE_API_TOKEN environment variable not set' unless @api_token
  end

  def call
    begin
      response = make_inference_request
      handle_response(response)
    rescue HTTParty::Error => e
      error_message = "HTTP error during HuggingFace inference: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error making HuggingFace inference: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def make_inference_request
    headers = {
      'Authorization' => "Bearer #{@api_token}",
      'Content-Type' => 'application/json'
    }

    payload = {
      'inputs' => @inputs
    }
    
    # Only include parameters if they are provided
    payload['parameters'] = @parameters unless @parameters.empty?

    self.class.post("/#{@model_id}",
      headers: headers,
      body: payload.to_json
    )
  end

  def handle_response(response)
    case response.code
    when 200
      Sublayer.configuration.logger.log(:info, "Successfully made inference request to HuggingFace model: #{@model_id}")
      response.parsed_response
    when 503
      # Model is loading
      error_message = "Model is still loading. Please retry after a few seconds."
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    else
      error_message = "HuggingFace API error: #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end