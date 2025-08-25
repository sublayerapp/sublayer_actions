require 'trello'

# Description: Sublayer::Action responsible for updating a task in Trello, such as changing the status of a card or moving it to a different list.
# This action integrates with Trello using the Trello Ruby SDK.
#
# It is initialized with a card_id, list_id (optional), name (optional), and description (optional).
# The action updates the Trello card based on the provided parameters and returns the updated card details.
#
# Example usage: When you want to update the status of a Trello card based on AI-driven insights or processes.

class TrelloUpdateTaskAction < Sublayer::Actions::Base
  def initialize(card_id:, list_id: nil, name: nil, description: nil)
    @card_id = card_id
    @list_id = list_id
    @name = name
    @description = description
    Trello.configure do |config|
      config.developer_public_key = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
      config.member_token = ENV['TRELLO_MEMBER_TOKEN']
    end
    @client = Trello::Client.new
  end

  def call
    card = @client.find(:card, @card_id)

    move_card(card) if @list_id
    update_card_name(card) if @name
    update_card_description(card) if @description

    Sublayer.configuration.logger.log(:info, "Trello card updated successfully: #{card.id}")
    card
  rescue Trello::Error => e
    error_message = "Error updating Trello card: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def move_card(card)
    card.move_to_list(@list_id)
  end

  def update_card_name(card)
    card.name = @name
    card.save
  end

  def update_card_description(card)
    card.desc = @description
    card.save
  end
end