# Description: Sublayer::Action responsible for generating a short summary of a given text using an LLM.
# It leverages the OpenAI API for summarization.
# Example usage: Condensing articles, reports, or any lengthy text for quick overviews or integration into other workflows.

class OpenAISummarizationAction < Sublayer::Actions::Base
  def initialize(text:, model: "gpt-3.5-turbo", max_tokens: 150)
    @text = text
    @model = model
    @max_tokens = max_tokens
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      response = @client.completions(
        parameters: {
          model: @model,
          prompt: "Please summarize the following text:\n\n#{@text}",
          max_tokens: @max_tokens,
          temperature: 0.5 # Adjust temperature for creativity vs. accuracy
        }
      )

      summary = response.choices[0].text.strip
      Sublayer.configuration.logger.log(:info, "Generated summary successfully")
      summary
    rescue OpenAI::Error => e
      error_message = "Error generating summary: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end