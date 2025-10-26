require 'trello'

# Description: Sublayer::Action responsible for creating a new card on a Trello board.
# This action integrates with Trello using the Trello API and allows adding AI-generated tasks or ideas
# to a Trello board for better task tracking and collaboration.
#
# It is initialized with board_id, list_id, card_name, and optionally description and due_date.
# It returns the ID of the created card.
#
# Example usage: When you want to convert AI-generated ideas into actionable tasks on Trello.

class TrelloCreateCardAction < Sublayer::Actions::Base
  def initialize(board_id:, list_id:, card_name:, description: '', due_date: nil)
    @board_id = board_id
    @list_id = list_id
    @card_name = card_name
    @description = description
    @due_date = due_date
    @client = Trello::Client.new(
      developer_public_key: ENV['TRELLO_PUBLIC_KEY'],
      member_token: ENV['TRELLO_MEMBER_TOKEN']
    )
  end

  def call
    create_card
  rescue Trello::Error => e
    error_message = "Error creating Trello card: \\#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "General error creating Trello card: \\#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def create_card
    card = Trello::Card.create(
      name: @card_name,
      list_id: @list_id,
      desc: @description,
      due: @due_date
    )
    Sublayer.configuration.logger.log(:info, "Card created successfully on Trello board with ID: \\#{card.id}")
    card.id
  end
end
