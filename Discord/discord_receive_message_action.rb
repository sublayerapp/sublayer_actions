require 'discordrb'

# Description: Sublayer::Action responsible for listening and retrieving incoming messages from a Discord channel.
# This action is useful for creating interactive AI applications using Discord as a communication platform.
#
# It is initialized with a bot_token and channel_id, and it retrieves messages which can be used to trigger further AI actions.
#
# Example usage: When you want to listen to messages in a Discord channel and perform certain actions based on their content.

class DiscordReceiveMessageAction < Sublayer::Actions::Base
  def initialize(bot_token:, channel_id:)
    @bot_token = bot_token
    @channel_id = channel_id
    @bot = Discordrb::Bot.new(token: @bot_token)
  end

  def call
    @bot.message(from: @channel_id) do |event|
      begin
        message_content = event.message.content
        Sublayer.configuration.logger.log(:info, "Received message: #{message_content}")
        # Here you can add logic to trigger AI actions based on message_content
      rescue StandardError => e
        Sublayer.configuration.logger.log(:error, "Error processing Discord message: #{e.message}")
      end
    end

    @bot.run
  end
end
