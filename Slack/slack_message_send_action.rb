require 'slack-ruby-client'

# Description: Sublayer::Action responsible for sending a message to a specific Slack channel or user.
# It can be used for notifications or updates from AI-driven processes.
#
# It is initialized with a channel (can be a channel name or user ID) and a message.
# It returns the timestamp of the sent message to confirm it was sent successfully.
#
# Example usage: When you want to send a notification or update from an AI process to a Slack channel or user.

class SlackMessageSendAction < Sublayer::Actions::Base
  def initialize(channel:, message:)
    @channel = channel
    @message = message
    @client = Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

  def call
    begin
      response = @client.chat_postMessage(channel: @channel, text: @message)
      logger.info "Message sent successfully to #{@channel}"
      response.ts
    rescue Slack::Web::Api::Errors::SlackError => e
      logger.error "Error sending Slack message: #{e.message}"
      raise e
    end
  end
end