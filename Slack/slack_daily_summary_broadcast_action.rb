# Sublayer::Action responsible for sending a daily summary of project progress or important updates to a designated Slack channel.
# This action can be scheduled to run at the end of the day to keep team members informed about the day's accomplishments.
#
# Requires: `slack-ruby-client` gem
# $ gem install slack-ruby-client
# Or add `gem 'slack-ruby-client'` to your Gemfile.

class SlackDailySummaryBroadcastAction < Sublayer::Actions::Base
  def initialize(channel:, summary:)
    @channel = channel
    @summary = summary
    @client = Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

  def call
    begin
      response = @client.chat_postMessage(channel: @channel, text: format_message(@summary))
      Sublayer.configuration.logger.log(:info, "Daily summary sent successfully to \\#{@channel}")
      response.ts
    rescue Slack::Web::Api::Errors::SlackError => e
      error_message = "Error sending daily summary to Slack: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def format_message(summary)
    "*Daily Project Summary*\n\n" + summary
  end
end