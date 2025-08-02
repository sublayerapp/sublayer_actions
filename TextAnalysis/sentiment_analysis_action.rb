# Description: Sublayer::Action for analyzing the sentiment of a given text.
# This action can be used in AI-driven workflows to determine sentiment scores or categories for given inputs.
#
# It is initialized with text and returns a sentiment score or category based on the analysis.
#
# Example usage: Analyse customer feedback to determine overall customer satisfaction.

class SentimentAnalysisAction < Sublayer::Actions::Base
  def initialize(text:)
    @text = text
    @client = SentimentAnalysis::Client.new
  end

  def call
    analyze_sentiment
  rescue StandardError => e
    error_message = "Error analyzing sentiment: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def analyze_sentiment
    begin
      response = @client.analyze(@text)
      sentiment_score = response[:score]
      sentiment_category = response[:category]
      Sublayer.configuration.logger.log(:info, "Sentiment analysis successful for text with score: #{sentiment_score}, category: #{sentiment_category}")
      { score: sentiment_score, category: sentiment_category }
    rescue StandardError => e
      error_message = "Error during sentiment analysis: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
