require 'openai'

# Description: Sublayer::Action responsible for making function calls to GPT models using OpenAI's API.
# This action simplifies the process of using GPT's function calling capabilities by handling
# all the API setup, function schema validation, and error handling.
#
# It is initialized with the model name, function schema, and function call parameters.
# It returns the function call response from GPT.
#
# Example usage: When you want to use GPT's function calling capabilities in a structured way,
# providing a specific JSON schema for the expected function and getting formatted responses.
#
# Required Environment Variables:
# - OPENAI_API_KEY: Your OpenAI API key

class GptFunctionCallAction < Sublayer::Actions::Base
  def initialize(model:, function_schema:, parameters:, temperature: 0.7)
    @model = model
    @function_schema = function_schema
    @parameters = parameters
    @temperature = temperature
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_schema
      response = make_function_call
      process_response(response)
    rescue JSON::Schema::ValidationError => e
      error_message = "Function schema validation error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue OpenAI::Error => e
      error_message = "OpenAI API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error in GPT function call: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_schema
    unless @function_schema.is_a?(Hash) && 
           @function_schema['name'].is_a?(String) && 
           @function_schema['parameters'].is_a?(Hash)
      raise StandardError, 'Invalid function schema format'
    end
  end

  def make_function_call
    @client.chat(
      parameters: {
        model: @model,
        messages: [{
          role: 'user',
          content: 'Function call request'
        }],
        functions: [@function_schema],
        function_call: { name: @function_schema['name'] },
        temperature: @temperature,
        parameters: @parameters
      }
    )
  end

  def process_response(response)
    message = response.dig('choices', 0, 'message')
    function_call = message['function_call']

    if function_call
      Sublayer.configuration.logger.log(
        :info,
        "Successfully executed GPT function call for #{@function_schema['name']}"
      )
      
      {
        name: function_call['name'],
        arguments: JSON.parse(function_call['arguments'])
      }
    else
      error_message = 'No function call in GPT response'
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
