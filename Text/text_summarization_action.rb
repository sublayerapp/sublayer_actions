# Description: Sublayer::Action responsible for summarizing text using a specified summarization technique.
#
# This action integrates with different text summarization techniques to provide concise summaries of input text.
#
# It is initialized with the text to be summarized and an optional summarization technique.
# It returns the summarized text.
#
# Example usage: When you want to summarize long documents or articles for quick understanding.

class TextSummarizationAction < Sublayer::Actions::Base
  def initialize(text:, summarization_technique: 'default')
    @text = text
    @summarization_technique = summarization_technique
  end

  def call
    begin
      summary = summarize_text
      Sublayer.configuration.logger.log(:info, "Text summarized successfully using \#{@summarization_technique} technique.")
      summary
    rescue StandardError => e
      error_message = "Error summarizing text: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def summarize_text
    # Implement different summarization techniques here
    case @summarization_technique
    when 'default'
      default_summarization
    when 'extractive'
      extractive_summarization
    when 'abstractive'
      abstractive_summarization
    else
      default_summarization
    end
  end

  def default_summarization
    # Basic summarization logic (e.g., first few sentences)
    sentences = @text.split('. ')
    sentences.take(3).join('. ') # Taking the first 3 sentences as a basic summary
  end

  def extractive_summarization
    # Extractive summarization logic (e.g., using keyword extraction and scoring)
    # Requires additional libraries or APIs for keyword extraction
    "Extractive summarization is not yet implemented. Please use default."
  end

  def abstractive_summarization
    # Abstractive summarization logic (e.g., using NLP models or APIs)
    # Requires integration with an NLP service like OpenAI or Cohere
    "Abstractive summarization is not yet implemented. Please use default."
  end
end