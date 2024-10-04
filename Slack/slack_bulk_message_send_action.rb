# Description: Sublayer::Action responsible for sending the same message to multiple Slack channels or users.
# It can be used for announcements or notifications intended for wide dissemination.
# 
# Requires: `slack-ruby-client` gem
# $ gem install slack-ruby-client
# Or
# add `gem "slack-ruby-client"` to your gemfile 
# and add `requires "slack-ruby-client"` somewhere in your app.
#
# It is initialized with an array of channels (which can be channel names or user IDs) and a message.
# It returns a hash with channels as keys and timestamps of the sent messages to confirm successful sending.

class SlackBulkMessageSendAction < Sublayer::Actions::Base
  def initialize(channels:, message:)
    @channels = channels
    @message = message
    @client = Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

  def call
    timestamps = {}
    @channels.each do |channel|
      begin
        response = @client.chat_postMessage(channel: channel, text: @message)
        Sublayer.configuration.logger.log(:info, "Message sent successfully to #{channel}")
        timestamps[channel] = response.ts
      rescue Slack::Web::Api::Errors::SlackError => e
        Sublayer.configuration.logger.log(:error, "Error sending Slack message to #{channel}: #{e.message}")
        timestamps[channel] = nil
      end
    end
    timestamps
  end
end
