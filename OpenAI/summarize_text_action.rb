# Description: Sublayer::Action responsible for summarizing a given text using a specified summarization technique.
# Currently, this action uses an abstractive summarization technique via the OpenAI API.
# Useful for condensing large documents or conversations into key points.
#
# It is initialized with a text to summarize and an optional model (defaults to 'gpt-3.5-turbo').
# It returns the summarized text.
#
# Example usage: When you want to condense a long document or a conversation into key points for further processing or display.

require 'openai'

class SummarizeTextAction < Sublayer::Actions::Base
  def initialize(text:, model: 'gpt-3.5-turbo')
    @text = text
    @model = model
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      response = @client.chat(
        parameters: {
          model: @model,
          messages: [
            {
              role: 'system',
              content: 'You are a helpful assistant that summarizes text in a concise and informative manner.'
            },
            {
              role: 'user',
              content: "Summarize the following text: #{@text}"
            }
          ],
          temperature: 0.7 # Adjust for desired creativity/conservatism
        }
      )

      summary = response.dig('choices', 0, 'message', 'content')

      if summary.nil? || summary.empty?
        error_message = "Failed to generate a summary from OpenAI.  Response: #{response}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

      Sublayer.configuration.logger.log(:info, "Text summarized successfully using model \#{@model}")

      summary
    rescue OpenAI::Error => e
      error_message = "Error summarizing text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
        Sublayer.configuration.logger.log(:error, e.message)
        raise e
    end
  end
end