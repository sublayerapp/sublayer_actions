# Description: Sublayer::Action to analyze the sentiment of a given text string using a fictional TextAnalysisAPI.
# It determines whether the sentiment is positive, negative, or neutral, useful for monitoring social media or customer feedback.

require 'text_analysis_api'  # fictional gem for text analysis

class SentimentAnalysisAction < Sublayer::Actions::Base
  def initialize(text:)
    @text = text
    @client = TextAnalysisAPI::Client.new(api_key: ENV['TEXT_ANALYSIS_API_KEY'])
  end

  def call
    response = @client.analyze_sentiment(text: @text)
    log_sentiment_analysis(response)
    response[:sentiment]
  rescue StandardError => e
    log_error(e)
    'unknown'
  end

  private

  def log_sentiment_analysis(response)
    puts "Sentiment Analysis Result: #{response[:sentiment]}", "Confidence: #{response[:confidence]}"
  end

  def log_error(error)
    puts "An error occurred during sentiment analysis: #{error.message}"
  end
end