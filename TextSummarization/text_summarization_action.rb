# Description: Sublayer::Action responsible for summarizing text using an LLM.
#
# This action takes a long text as input and returns a shorter, summarized version.
# It leverages an LLM (defaulting to OpenAI's GPT-3.5 Turbo) for summarization.
#
# It is initialized with the text to summarize and optional parameters such as the LLM model, and a custom prompt.
# It returns the summarized text.
#
# Example usage: When you need to condense a large document or article into a more manageable summary for further processing or display.

require 'openai'

class TextSummarization::TextSummarizationAction < Sublayer::Actions::Base
  DEFAULT_MODEL = "gpt-3.5-turbo".freeze

  def initialize(text:, model: DEFAULT_MODEL, custom_prompt: nil)
    @text = text
    @model = model
    @custom_prompt = custom_prompt
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      prompt = @custom_prompt || generate_default_prompt
      messages = [{ role: "system", content: prompt }, { role: "user", content: @text }]

      response = @client.chat(parameters: {
        model: @model,
        messages: messages,
        temperature: 0.7
      })

      summary = response.dig("choices", 0, "message", "content")

      if summary.nil? || summary.empty?
        error_message = "Failed to extract summary from OpenAI response."
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

      Sublayer.configuration.logger.log(:info, "Text summarized successfully using model \#{@model}")
      summary
    rescue OpenAI::Error => e
      error_message = "Error during text summarization: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error during text summarization: \#{e.message}")
      raise e
    end
  end

  private

  def generate_default_prompt
    "You are a highly skilled AI trained in summarizing text. Summarize the following text into a concise summary, capturing the main points and key information."
  end
end