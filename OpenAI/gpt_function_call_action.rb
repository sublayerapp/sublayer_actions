require 'openai'

# Description: Sublayer::Action responsible for executing GPT function calls with provided parameters.
# This action handles the interaction with OpenAI's API for function calling, including rate limiting
# and error handling. It serves as a base action for other Sublayer actions that need to make
# structured GPT function calls.
#
# It is initialized with a model name, function definition, and function parameters.
# It returns the structured response from the GPT function call.
#
# Example usage: When you want to make a structured function call to GPT and get back
# specifically formatted data rather than free-form text.

class GptFunctionCallAction < Sublayer::Actions::Base
  def initialize(model:, function_name:, function_definition:, parameters:)
    @model = model || 'gpt-4'
    @function_name = function_name
    @function_definition = function_definition
    @parameters = parameters
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    @max_retries = 3
    @base_delay = 1 # Base delay in seconds for exponential backoff
  end

  def call
    attempt = 0
    begin
      attempt += 1
      response = make_function_call
      
      Sublayer.configuration.logger.log(:info, "Successfully executed GPT function call for #{@function_name}")
      
      # Return the function call result
      response.dig('choices', 0, 'message', 'function_call', 'arguments')
    rescue OpenAI::Error => e
      handle_openai_error(e, attempt)
    rescue StandardError => e
      error_message = "Unexpected error in GPT function call: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def make_function_call
    @client.chat(
      parameters: {
        model: @model,
        messages: [
          { role: 'user', content: format_content },
        ],
        functions: [@function_definition],
        function_call: { name: @function_name }
      }
    )
  end

  def format_content
    # Convert parameters to a natural language request that triggers the function
    "Please execute the #{@function_name} function with the following parameters: #{@parameters.to_json}"
  end

  def handle_openai_error(error, attempt)
    case error
    when OpenAI::RateLimitError
      if attempt < @max_retries
        sleep_duration = @base_delay * (2 ** (attempt - 1)) # Exponential backoff
        Sublayer.configuration.logger.log(:warn, "Rate limit reached, retrying in #{sleep_duration} seconds")
        sleep(sleep_duration)
        retry
      else
        error_message = "Rate limit exceeded after #{@max_retries} retries"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    when OpenAI::InvalidRequestError
      error_message = "Invalid request to OpenAI API: #{error.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    else
      error_message = "OpenAI API error: #{error.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end