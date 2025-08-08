# Description: Sublayer::Action responsible for summarizing text content.
# This action can either extract key sentences or generate a concise summary of the input text.
#
# It is initialized with the text to summarize and a summarization strategy (either 'extractive' or 'generative').
# For extractive summarization, it identifies and extracts the most important sentences.
# For generative summarization, it uses an LLM to generate a new summary.
#
# Example usage: When you want to condense large amounts of text for AI processing or presentation.

class TextSummarizationAction < Sublayer::Actions::Base
  def initialize(text:, summarization_strategy: 'extractive', llm_model: 'gpt-3.5-turbo')
    @text = text
    @summarization_strategy = summarization_strategy
    @llm_model = llm_model
  end

  def call
    begin
      case @summarization_strategy
      when 'extractive'
        summarize_extractively
      when 'generative'
        summarize_generatively
      else
        raise ArgumentError, "Invalid summarization strategy: #{@summarization_strategy}. Must be 'extractive' or 'generative'."
      end
    rescue StandardError => e
      error_message = "Error summarizing text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def summarize_extractively
    # Placeholder for extractive summarization logic (e.g., using textrank or similar).
    # This is a simplified example and would require a gem like 'summarize' for real functionality.
    sentences = @text.split(/[.?!]/).map(&:strip).reject(&:empty?)
    num_sentences_to_extract = (sentences.size * 0.3).round # Extract top 30% of sentences
    extracted_sentences = sentences.first(num_sentences_to_extract)
    extracted_sentences.join('. ') + '.'
  end

  def summarize_generatively
    require 'openai'
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    prompt = "Summarize the following text: #{@text}"

    response = client.chat(parameters: {
      model: @llm_model,
      messages: [{ role: 'user', content: prompt }]
    })

    response.dig('choices', 0, 'message', 'content')
  end
end