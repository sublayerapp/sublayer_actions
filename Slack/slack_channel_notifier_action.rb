# Description: Sublayer::Action responsible for notifying a specified Slack channel of significant updates or changes.
# This action enhances collaboration and communication within a project by sending automated notifications to a Slack channel.
# 
# Requires: `slack-ruby-client` gem
# $ gem install slack-ruby-client
# Or
# add `gem "slack-ruby-client"` to your gemfile 
# and add `requires "slack-ruby-client"` somewhere in your app.
#
# It is initialized with a channel (can be a channel name or user ID) and a message describing the update or change.
# It returns the timestamp of the sent message to confirm it was sent successfully.
#
# Example usage: When you want to keep your team informed about critical changes in a project by sending Slack notifications.

class SlackChannelNotifierAction < Sublayer::Actions::Base
  def initialize(channel:, update_message:)
    @channel = channel
    @update_message = update_message
    @client = Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

  def call
    begin
      response = @client.chat_postMessage(channel: @channel, text: format_message)
      Sublayer.configuration.logger.log(:info, "Update sent successfully to #{@channel}")
      response.ts
    rescue Slack::Web::Api::Errors::SlackError => e
      Sublayer.configuration.logger.log(:error, "Error sending update to Slack: #{e.message}")
      raise e
    end
  end

  private

  def format_message
    "[Project Update] #{@update_message}"
  end
end
