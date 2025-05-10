# Description: Sublayer::Action responsible for updating the status message of a specified Slack user.
# It can be used to indicate the user's current tasks, availability, or any other status-related information.
# 
# Requires: `slack-ruby-client` gem
# $ gem install slack-ruby-client
# Or
# add `gem "slack-ruby-client"` to your Gemfile
# and add `require "slack-ruby-client"` somewhere in your app.
#
# It is initialized with a user ID and a status text.
# It returns the updated status as confirmation.
#
# Example usage: When you want to automatically update a user's status, such as setting their current task or availability,
# from an AI-driven workflow.

class SlackUserStatusUpdateAction < Sublayer::Actions::Base
  def initialize(user_id:, status_text:, emoji: nil, expiration: nil)
    @user_id = user_id
    @status_text = status_text
    @emoji = emoji
    @expiration = expiration
    @client = Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

  def call
    begin
      profile = {
        status_text: @status_text,
        status_emoji: @emoji,
        status_expiration: @expiration
      }.compact

      response = @client.users_profile_set(user: @user_id, profile: profile)
      Sublayer.configuration.logger.log(:info, "Status updated successfully for Slack user #{@user_id}")
      response.profile
    rescue Slack::Web::Api::Errors::SlackError => e
      error_message = "Error updating Slack user status: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
