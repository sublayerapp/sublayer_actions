# Description: Sublayer::Action responsible for analyzing text sentiment and categorizing it as positive, negative, or neutral.
# This action is intended to enhance AI response systems by considering the emotional tone of the text.
#
# Example usage: Use this action when you want to adjust AI responses based on the sentiment of user input or when analyzing documents for emotional content.

require 'sentimental'

class TextSentimentAnalysisAction < Sublayer::Actions::Base
  def initialize(text:)
    @text = text
    @analyzer = Sentimental.new
    @analyzer.load_defaults
  end

  def call
    begin
      sentiment = analyze_sentiment
      Sublayer.configuration.logger.log(:info, "Sentiment analysis completed. Result: #{sentiment}")
      sentiment
    rescue StandardError => e
      error_message = "Error in sentiment analysis: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def analyze_sentiment
    @analyzer.sentiment(@text).to_s
  end
end
