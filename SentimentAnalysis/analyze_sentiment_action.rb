require 'sentiment'

# Description: Sublayer::Action responsible for analyzing the sentiment of a given text.
# It uses the 'sentiment' gem to determine the sentiment score of the input text.
#
# It is initialized with a text string and returns a sentiment score between -1 (negative) and 1 (positive).
#
# Example usage: When you want to analyze customer feedback, detect negative comments, or understand the emotional tone of a text.

class SentimentAnalysis::AnalyzeSentimentAction < Sublayer::Actions::Base
  def initialize(text:)
    @text = text
    @analyzer = Sentiment::Analyzer.new
  end

  def call
    begin
      sentiment = @analyzer.analyze(@text)
      score = calculate_score(sentiment)

      Sublayer.configuration.logger.log(:info, "Sentiment score for text: \#{score}")
      score
    rescue StandardError => e
      error_message = "Error analyzing sentiment: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def calculate_score(sentiment)
    # Calculate a single score from the sentiment analysis results.
    # This is a simple example; you might want to adjust the formula based on your needs.
    positive = sentiment.positive.to_f
    negative = sentiment.negative.to_f
    total = positive + negative

    return 0.0 if total == 0

    (positive - negative) / total
  end
end