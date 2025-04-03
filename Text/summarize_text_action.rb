# Description: Sublayer::Action responsible for summarizing a long piece of text using a specified summarization technique.
#
# It is initialized with the text to summarize and an optional summarization technique (defaulting to an abstractive summarization using OpenAI).
# It returns the summarized text.
#
# Example usage: When you want to quickly understand the content of a large document or article.

require 'openai'

class SummarizeTextAction < Sublayer::Actions::Base
  def initialize(text:, summarization_technique: 'openai')
    @text = text
    @summarization_technique = summarization_technique
  end

  def call
    case @summarization_technique
    when 'openai'
      summarize_with_openai
    else
      raise ArgumentError, "Unsupported summarization technique: \#{@summarization_technique}"
    end
  rescue StandardError => e
    error_message = "Error summarizing text: \#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def summarize_with_openai
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    response = client.completions(parameters: {
      model: "text-davinci-003",
      prompt: "Summarize the following text: \n\n \#{@text}",
      temperature: 0.3,
      max_tokens: 300
    })

    summary = response['choices'][0]['text'].strip
    Sublayer.configuration.logger.log(:info, "Text summarized successfully using OpenAI.")
    summary
  rescue OpenAI::Error => e
    error_message = "OpenAI Error: \#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end