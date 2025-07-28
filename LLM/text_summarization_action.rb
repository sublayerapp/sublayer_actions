# Description: Sublayer::Action responsible for summarizing text using an LLM.
#
# It is initialized with the text to summarize and returns a concise summary.
#
# Example usage: When you have a long document or text that exceeds the context window of your LLM and want to summarize it before processing it further.

class TextSummarizationAction < Sublayer::Actions::Base
  def initialize(text:, model: 'gpt-3.5-turbo', max_tokens: 500)
    @text = text
    @model = model
    @max_tokens = max_tokens
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
              content: 'You are a helpful assistant that summarizes text concisely.'
            },
            {
              role: 'user',
              content: "Please summarize the following text: \n\n #{@text}"
            }
          ],
          max_tokens: @max_tokens
        }
      )

      summary = response.dig('choices', 0, 'message', 'content')

      if summary.nil?
        error_message = "Failed to extract summary from OpenAI response: \#{response}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

      Sublayer.configuration.logger.log(:info, "Successfully summarized text using \#{@model}")
      summary

    rescue OpenAI::Error => e
      error_message = "Error summarizing text: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
        error_message = "Error during text summarization: \#{e.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise e
    end
  end
end