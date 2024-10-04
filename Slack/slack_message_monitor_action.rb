class SlackMessageMonitorAction < Sublayer::Actions::Base
  # Description: Sublayer::Action to monitor a Slack channel for messages matching specific criteria.
  # It uses the Slack Real Time Messaging API to listen for new messages and returns matching messages.
  #
  # Example usage:
  #   - Trigger AI workflows based on user requests or keywords.
  #   - Monitor channels for specific events or discussions.
  #
  # Requirements:
  #   - `slack-ruby-client` gem
  #   - A Slack App with the following scopes:
  #     - `channels:history`
  #     - `groups:history`
  #     - `im:history`
  #     - `mpim:history`
  #
  # Note: This action requires a persistent connection to the Slack API.

  def initialize(channel:, pattern:, timeout: 60)
    @channel = channel
    @pattern = pattern
    @timeout = timeout
    @client = Slack::Web::Client.new(token: ENV['SLACK_API_TOKEN'])
    @rtm_client = Slack::RealTime::Client.new(token: ENV['SLACK_API_TOKEN'])
  end

  def call
    Sublayer.configuration.logger.log(:info, "Monitoring channel #{@channel} for messages matching '#{@pattern}'...")

    begin
      # Get channel ID from channel name
      channel_id = @client.channels_list['channels'].find { |c| c['name'] == @channel }['id']

      # Start listening for messages
      @rtm_client.on :message do |data|
        if data.channel == channel_id && data.text =~ @pattern
          Sublayer.configuration.logger.log(:info, "Found matching message: \"#{data.text}\"")
          return data.text
        end
      end

      @rtm_client.start_async
      sleep @timeout

      Sublayer.configuration.logger.log(:warn, "No matching messages found after #{@timeout} seconds.")
      return nil
    rescue Slack::Web::Api::Errors::SlackError => e
      Sublayer.configuration.logger.log(:error, "Error monitoring Slack channel: #{e.message}")
      raise e
    end
  end
end