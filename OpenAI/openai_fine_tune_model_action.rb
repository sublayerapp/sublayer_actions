require 'openai'

# Description: Sublayer::Action responsible for initiating a fine-tuning process for OpenAI models.
# This action allows customization of LLM outputs based on specific datasets or requirements.
#
# It is initialized with a training_file_id, model, and optional parameters for managing the fine-tuning process.
# It returns the fine-tune job ID for tracking the status.
#
# Example usage: When you want to fine-tune an OpenAI model using specific data to customize outputs for a particular application.

class OpenAIFineTuneModelAction < Sublayer::Actions::Base
  def initialize(training_file_id:, model:, n_epochs: 4, batch_size: nil, learning_rate_multiplier: nil)
    @training_file_id = training_file_id
    @model = model
    @n_epochs = n_epochs
    @batch_size = batch_size
    @learning_rate_multiplier = learning_rate_multiplier
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      fine_tune_params = {
        training_file: @training_file_id,
        model: @model,
        n_epochs: @n_epochs,
      }
      fine_tune_params[:batch_size] = @batch_size if @batch_size
      fine_tune_params[:learning_rate_multiplier] = @learning_rate_multiplier if @learning_rate_multiplier
      
      response = @client.finetunes.create(fine_tune_params)
      fine_tune_id = response['id']
      Sublayer.configuration.logger.log(:info, "Fine-tuning initiated successfully with ID: #{fine_tune_id}")
      fine_tune_id
    rescue OpenAI::Error => e
      error_message = "Error initiating fine-tuning: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end