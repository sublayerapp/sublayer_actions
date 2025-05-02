# Description: Sublayer::Action responsible for performing sentiment analysis on a given text and returning a sentiment score or label.
# This action is useful for understanding the sentiment expressed in textual data, aiding in decision-making processes.
#
# Requires: 'sentimental' gem for sentiment analysis
# $ gem install sentimental
# Or add `gem 'sentimental'` to your Gemfile
#
# It is initialized with a text and optional language parameter.
# It returns a sentiment score or label to describe the text's sentiment.
#
# Example usage: When you want to analyze user feedback to understand customers' feelings towards a product.

require 'sentimental'

class NaturalLanguageSentimentAnalysisAction < Sublayer::Actions::Base
  def initialize(text:, language: 'en')
    @text = text
    @language = language
    Sentimental.load_defaults
    @analyzer = Sentimental.new
    @analyzer.language = @language
  end

  def call
    begin
      score = @analyzer.score(@text)
      label = @analyzer.sentiment(@text)
      Sublayer.configuration.logger.log(:info, "Sentiment analysis completed successfully with score: #{score}, label: #{label}")
      { score: score, label: label }
    rescue StandardError => e
      error_message = "Error performing sentiment analysis: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end