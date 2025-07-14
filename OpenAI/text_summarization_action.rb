# Description: Sublayer::Action responsible for summarizing a given text using an LLM.
#
# It is initialized with a text and optionally a model name. It uses the OpenAI API to summarize the text.
# It returns the summarized text.
#
# Example usage: When you want to summarize a long document or article for use in a prompt.

require 'openai'

class TextSummarizationAction < Sublayer::Actions::Base
  def initialize(text:, model_name: 'gpt-3.5-turbo')
    @text = text
    @model_name = model_name
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      response = @client.chat(
        parameters: {
          model: @model_name,
          messages: [
            {
              role: 'system',
              content: 'You are a helpful assistant that summarizes text.'
            },
            {
              role: 'user',
              content: "Please summarize the following text:\n\n#{@text}"
            }
          ],
          temperature: 0.7
        }
      )

      summary = response.dig('choices', 0, 'message', 'content')

      if summary.nil?
        error_message = "Failed to extract summary from OpenAI response: #{response}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

      Sublayer.configuration.logger.log(:info, "Text summarized successfully using #{@model_name}")
      summary
    rescue OpenAI::Error => e
      error_message = "Error summarizing text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during text summarization: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end