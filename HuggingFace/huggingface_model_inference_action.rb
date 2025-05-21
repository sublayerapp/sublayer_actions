require 'httparty'

# Description: Sublayer::Action responsible for sending requests to deployed models on HuggingFace's Inference API.
# This action enables easy integration of specialized AI models into Sublayer workflows.
#
# Requires: 'httparty' gem
# $ gem install httparty
# Or add `gem 'httparty'` to your Gemfile
#
# It is initialized with a model_id and inputs for the model.
# Optionally, accepts task_type to help format the request appropriately.
# Returns the model's inference results.
#
# Example usage: When you want to use specialized AI models (like computer vision or audio processing)
# as part of your Sublayer workflow.
#
# task_type examples:
# - 'text-classification'
# - 'token-classification'
# - 'question-answering'
# - 'image-classification'
# - 'image-to-text'
# - 'text-to-speech'
# - 'automatic-speech-recognition'

class HuggingfaceModelInferenceAction < Sublayer::Actions::Base
  include HTTParty
  base_uri 'https://api-inference.huggingface.co/models'

  def initialize(model_id:, inputs:, task_type: nil)
    @model_id = model_id
    @inputs = inputs
    @task_type = task_type
    @api_token = ENV['HUGGINGFACE_API_TOKEN']
  end

  def call
    begin
      response = make_inference_request
      handle_response(response)
    rescue HTTParty::Error => e
      error_message = "HTTP error during inference request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error making inference request: #{e.message}"
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

    body = format_request_body

    self.class.post("/#{@model_id}",
      headers: headers,
      body: body.to_json
    )
  end

  def format_request_body
    case @task_type
    when 'question-answering'
      {
        question: @inputs[:question],
        context: @inputs[:context]
      }
    when 'text-classification', 'token-classification'
      {
        inputs: @inputs
      }
    when 'image-classification', 'image-to-text'
      # For image tasks, inputs should be base64 encoded image
      {
        inputs: @inputs,
        options: { wait_for_model: true }
      }
    else
      # Default format for most tasks
      {
        inputs: @inputs
      }
    end
  end

  def handle_response(response)
    case response.code
    when 200
      Sublayer.configuration.logger.log(:info, "Successfully received inference results for model #{@model_id}")
      response.parsed_response
    when 503
      error_message = "Model is loading. Please retry after a few seconds."
      Sublayer.configuration.logger.log(:warn, error_message)
      raise StandardError, error_message
    else
      error_message = "Inference request failed: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end