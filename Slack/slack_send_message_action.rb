# Description: Sublayer::Action responsible for sending a message to a Slack channel.
#
# It is initialized with a channel_id and a message text. The message is sent to the specified Slack channel when the action is called.
#
# Example usage: You can use this action to automate sending notifications or updates to a team channel after certain events or tasks are completed.

require 'slack-ruby-client'

class SlackSendMessageAction < Sublayer::Actions::Base
  def initialize(channel_id:, message_text:, **kwargs)
    super(**kwargs)
    @channel_id = channel_id
    @message_text = message_text
    configure_slack_client
  end

  def call
    begin
      response = @client.chat_postMessage(channel: @channel_id, text: @message_text)
      if response.ok
        logger.info("Message sent to channel #{@channel_id}: #{@message_text}")
      else
        logger.error("Failed to send message: #{response['error']}")
      end
    rescue Slack::Web::Api::Errors::SlackError => e
      logger.error("Slack API error: #{e.message}")
    rescue StandardError => e
      logger.error("Unexpected error: #{e.message}")
    end
  end

  private

  def configure_slack_client
    Slack.configure do |config|
      config.token = ENV['SLACK_API_TOKEN']
    end
    @client = Slack::Web::Client.new
  end
end
