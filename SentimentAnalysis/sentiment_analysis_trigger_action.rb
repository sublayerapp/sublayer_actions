require 'sentimental'

# Description: Sublayer::Action responsible for analyzing sentiment of a given text and triggering different actions based on sentiment results.
# Useful for customer support automation and monitoring.
#
# It is initialized with a text and provides results as positive, negative, or neutral.
# Based on the sentiment, it can trigger different workflows like escalating or notifying relevant stakeholders.
#
# Example usage: Automating responses or alerts in customer service based on the sentiment of the input text.

class SentimentAnalysisTriggerAction < Sublayer::Actions::Base
  def initialize(text:)
    @text = text
    @analyzer = Sentimental.new
    @analyzer.load_defaults
  end

  def call
    sentiment = analyze_sentiment
    handle_sentiment(sentiment)
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error analyzing sentiment: #{e.message}")
    raise e
  end

  private

  def analyze_sentiment
    Sentimental.load_defaults
    @analyzer.sentiment(@text)
  rescue StandardError => e
    error_message = "Error during sentiment analysis: \\#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  def handle_sentiment(sentiment)
    case sentiment
    when :positive
      Sublayer.configuration.logger.log(:info, "Positive sentiment detected. Triggering positive workflow.")
      # implement positive sentiment workflow
    when :negative
      Sublayer.configuration.logger.log(:info, "Negative sentiment detected. Triggering escalation.")
      # implement negative sentiment escalation workflow
    when :neutral
      Sublayer.configuration.logger.log(:info, "Neutral sentiment detected. No action required.")
      # implement neutral sentiment workflow, if necessary
    end
  end
end
