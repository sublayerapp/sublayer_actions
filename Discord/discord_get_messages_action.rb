require 'discordrb'

# Description: Sublayer::Action responsible for retrieving a list of messages from a Discord channel.
# This action is intended to be used for gathering context from Discord conversations.
#
# It is initialized with a bot_token and a channel_id. You'll need to create a Discord bot and add it to your server to get these.
# It returns an array of the last 100 messages in the channel.
#
# Example usage: When you want to get context from a Discord channel to use in an LLM prompt

class DiscordGetMessagesAction < Sublayer::Actions::Base
  def initialize(bot_token:, channel_id:)
    @bot_token = bot_token
    @channel_id = channel_id
  end

  def call
    bot = Discordrb::Bot.new(token: @bot_token)
    channel = bot.channel(@channel_id)
    begin
      messages = channel.messages(limit: 100).map(&:content)
      Sublayer.configuration.logger.log(:info, "Successfully fetched messages from Discord channel")
      messages
    rescue Discordrb::Errors::NoPermission
      Sublayer.configuration.logger.log(:error, "The bot does not have permission to access this channel.")
      raise "The bot does not have permission to access this channel." 
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error fetching messages from Discord channel: #{e.message}")
      raise e
    end
  end
end