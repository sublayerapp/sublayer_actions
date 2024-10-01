# Description: Sublayer::Action responsible for sending a message to a specified Slack channel or user.
# It uses the Slack Web API to send messages.
#
# It is initialized with a channel (can be a channel name or user ID) and a message.
# It returns the ts (timestamp) of the sent message to verify it was sent successfully.
#
# Example usage: When you want to send automated notifications or updates from AI-driven processes
# to team communication channels in Slack.

require 'slack-ruby-client'

class SlackSendMessageAction < Sublayer::Actions::Base
  def initialize(channel:, message:, token: nil)
    @channel = channel
    @message = message
    @token = token || ENV['SLACK_API_TOKEN']
    
    raise ArgumentError, 'Slack API token is required' if @token.nil? || @token.empty?
    
    Slack.configure do |config|
      config.token = @token
    end
    
    @client = Slack::Web::Client.new
  end

  def call
    begin
      response = @client.chat_postMessage(channel: @channel, text: @message)
      
      if response['ok']
        puts "Message sent successfully to #{@channel}"
        response['ts']  # Return the timestamp of the sent message
      else
        raise "Failed to send message: #{response['error']}"
      end
    rescue Slack::Web::Api::Errors::SlackError => e
      puts "Slack API error: #{e.message}"
      raise
    rescue StandardError => e
      puts "Unexpected error: #{e.message}"
      raise
    end
  end
end
