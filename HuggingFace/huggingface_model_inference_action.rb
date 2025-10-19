require 'net/http'
require 'uri'
require 'json'

# Description: Sublayer::Action responsible for making inference calls to deployed Hugging Face model endpoints.
# This action allows integration with any model hosted on Hugging Face's model inference API,
# enabling access to specialized models for various tasks like translation, classification, or domain-specific analysis.
#
# It is initialized with a model_id and input_data. Optionally, accepts api_url for private deployments.
# Returns the model's inference response.
#
# Requires: Hugging Face API token set as HUGGINGFACE_API_TOKEN environment variable
#
# Example usage: 
# - Text classification with a specialized model
# - Language translation with specific language pair models
# - Domain-specific analysis with field-expert models

class HuggingfaceModelInferenceAction < Sublayer::Actions::Base
  def initialize(model_id:, input_data:, api_url: nil)
    @model_id = model_id
    @input_data = input_data
    @api_url = api_url || "https://api-inference.huggingface.co/models/"
    @api_token = ENV['HUGGINGFACE_API_TOKEN']
    
    raise StandardError, 'HUGGINGFACE_API_TOKEN environment variable not set' unless @api_token
  end

  def call
    begin
      response = make_inference_request
      handle_response(response)
    rescue StandardError => e
      error_message = "Error making Hugging Face inference request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def make_inference_request
    uri = URI.join(@api_url, @model_id)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@api_token}"
    request['Content-Type'] = 'application/json'
    request.body = @input_data.to_json

    Sublayer.configuration.logger.log(:info, "Making inference request to #{@model_id}")
    http.request(request)
  end

  def handle_response(response)
    case response
    when Net::HTTPSuccess
      Sublayer.configuration.logger.log(:info, "Successfully received inference response from #{@model_id}")
      JSON.parse(response.body)
    when Net::HTTPTooManyRequests
      error_message = "Rate limit exceeded for Hugging Face API"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    else
      error_message = "Hugging Face API request failed: #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end