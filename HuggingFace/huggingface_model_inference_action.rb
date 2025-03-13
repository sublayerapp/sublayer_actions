require 'httparty'

# Description: Sublayer::Action responsible for executing inference on a specified Hugging Face model.
# This action enables easy integration with open source AI models hosted on Hugging Face for specialized tasks.
#
# Requires: 'httparty' gem
# $ gem install httparty
# Or add `gem 'httparty'` to your Gemfile
#
# It is initialized with a model_id and inputs for the model.
# It returns the model's inference output.
#
# Example usage: When you want to perform specific ML tasks like sentiment analysis, text classification,
# or other specialized operations using Hugging Face's hosted models.
#
# Usage example:
# action = HuggingFaceModelInferenceAction.new(
#   model_id: 'distilbert-base-uncased-finetuned-sst-2-english',
#   inputs: 'I love this product!'
# )
# result = action.call
# # Returns sentiment analysis results

class HuggingFaceModelInferenceAction < Sublayer::Actions::Base
  include HTTParty
  base_uri 'https://api-inference.huggingface.co/models'
  
  def initialize(model_id:, inputs:, options: {})
    @model_id = model_id
    @inputs = inputs
    @options = options
    @api_token = ENV['HUGGINGFACE_API_TOKEN']
    
    raise ArgumentError, 'HUGGINGFACE_API_TOKEN environment variable is not set' if @api_token.nil?
  end

  def call
    begin
      response = make_inference_request
      validate_and_process_response(response)
    rescue HTTParty::Error => e
      error_message = "HTTP error during Hugging Face inference: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during Hugging Face inference: #{e.message}"
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
      inputs: @inputs
    }.merge(@options)

    Sublayer.configuration.logger.log(:info, "Making inference request to Hugging Face model: #{@model_id}")
    
    self.class.post("/#{@model_id}",
      headers: headers,
      body: payload.to_json
    )
  end

  def validate_and_process_response(response)
    case response.code
    when 200
      Sublayer.configuration.logger.log(:info, "Successfully received inference results from #{@model_id}")
      response.parsed_response
    when 404
      error_message = "Model not found: #{@model_id}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    when 400
      error_message = "Bad request: #{response.parsed_response['error']}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    else
      error_message = "Unexpected response (#{response.code}): #{response.parsed_response['error']}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end