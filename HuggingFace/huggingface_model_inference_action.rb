require 'huggingface_hub'

# Description: Sublayer::Action responsible for performing inference using Hugging Face models.
# This action enables integration of open-source models from Hugging Face into Sublayer workflows,
# complementing API-based services like OpenAI.
#
# Requires: 'huggingface_hub' gem
# $ gem install huggingface_hub
# Or add `gem 'huggingface_hub'` to your Gemfile
#
# It is initialized with a model_id, input text, and optional parameters like task type and model options.
# It returns the model's inference results.
#
# Example usage: When you want to use specific open-source models from Hugging Face for tasks like
# text classification, token classification, translation, or text generation in your Sublayer workflow.

class HuggingFaceModelInferenceAction < Sublayer::Actions::Base
  def initialize(model_id:, input_text:, task: nil, model_options: {})
    @model_id = model_id
    @input_text = input_text
    @task = task
    @model_options = model_options
    @api = HuggingFace::Hub::InferenceAPI.new(
      token: ENV['HUGGINGFACE_API_TOKEN'],
      model: @model_id
    )
  end

  def call
    begin
      result = perform_inference
      Sublayer.configuration.logger.log(:info, "Successfully performed inference using model: #{@model_id}")
      result
    rescue HuggingFace::Hub::Error => e
      error_message = "HuggingFace API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error performing model inference: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def perform_inference
    if @task
      @api.inference(@input_text, task: @task, **@model_options)
    else
      @api.inference(@input_text, **@model_options)
    end
  end
end