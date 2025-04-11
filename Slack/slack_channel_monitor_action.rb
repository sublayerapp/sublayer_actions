# Description: Sublayer::Action responsible for monitoring a Slack channel for specified keywords or sentiment.
# This action is useful for keeping track of team mood or any issues in real-time.
# 
# Requires: `slack-ruby-client` gem
# $ gem install slack-ruby-client
# Or
# add `gem "slack-ruby-client"` to your gemfile
# and add `requires "slack-ruby-client"` somewhere in your app.
#
# It is initialized with a channel (can be a channel name or ID), keywords, and sentiment to monitor.
# It alerts on the detection of those keywords or sentiment, useful for AI-driven workflows or alerts.
#
# Example usage: When you want to monitor team communication for specific issues or mood changes.

class SlackChannelMonitorAction < Sublayer::Actions::Base
  require 'slack-ruby-client'
  
  def initialize(channel:, keywords: [], sentiment: nil)
    @channel = channel
    @keywords = keywords
    @sentiment = sentiment
    @client = Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

  def call
    begin
      monitor_channel
    rescue Slack::Web::Api::Errors::SlackError => e
      Sublayer.configuration.logger.log(:error, "Error monitoring Slack channel: #{e.message}")
      raise e
    end
  end

  private

  def monitor_channel
    @client.channels_history(channel: @channel, count: 100) do |response|
      messages = response.messages
      messages.each do |message|
        check_message_for_keywords_and_sentiment(message.text)
      end
    end
  end

  def check_message_for_keywords_and_sentiment(text)
    @keywords.each do |keyword|
      if text.include?(keyword)
        Sublayer.configuration.logger.log(:info, "Keyword '#{keyword}' detected in Slack channel #{@channel}")
        # Additional actions can be performed here
      end
    end
    
    if @sentiment && analyze_sentiment(text) == @sentiment
      Sublayer.configuration.logger.log(:info, "Sentiment '#{@sentiment}' detected in Slack channel #{@channel}")
      # Additional actions can be performed here
    end
  end

  def analyze_sentiment(text)
    # Placeholder for sentiment analysis logic, can be integrated with an external API or library
    # For simplicity, let's assume it returns 'positive', 'negative', or 'neutral'
    'neutral' # Dummy return value
  end
end
