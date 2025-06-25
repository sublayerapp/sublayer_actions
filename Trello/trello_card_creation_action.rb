require 'trello'

# Description: Sublayer::Action responsible for creating a card in a Trello board.
# This action integrates with Trello API to facilitate task management and project tracking.
#
# It is initialized with a board_id, list_id, name, and description, returning the card id to confirm creation.
#
# Example usage: When you want to create Trello cards based on AI-generated task lists for efficient task management.

class TrelloCardCreationAction < Sublayer::Actions::Base
  def initialize(board_id:, list_id:, name:, description: nil)
    @board_id = board_id
    @list_id = list_id
    @name = name
    @description = description
    @client = Trello::Client.new(
      developer_public_key: ENV['TRELLO_DEVELOPER_PUBLIC_KEY'],
      member_token: ENV['TRELLO_MEMBER_TOKEN']
    )
  end

  def call
    create_card
  rescue StandardError => e
    error_message = "Error creating Trello card: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def create_card
    list = @client.find(:list, @list_id)
    card = list.cards.create(name: @name, desc: @description)
    Sublayer.configuration.logger.log(:info, "Trello card created successfully with ID: #{card.id}")
    card.id
  end
end
