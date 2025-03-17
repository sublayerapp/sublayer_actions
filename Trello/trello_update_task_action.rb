# Description: Sublayer::Action responsible for updating a task on a Trello board.
# This action allows for integration with Trello, a popular project management tool.
# It can be used to update task details based on AI-generated insights or status changes.
#
# Requires: 'ruby-trello' gem
# $ gem install ruby-trello
# Or add `gem 'ruby-trello'` to your Gemfile
#
# It is initialized with board_id, list_id, task_id, name (for new task name),
# description (for updating description), and status (for moving task).
# It returns a success message on successful update.
#
# Example usage: When you want to update a Trello task's details based on a workflow trigger.

require 'trello'

class TrelloUpdateTaskAction < Sublayer::Actions::Base
  def initialize(board_id:, list_id:, task_id:, name: nil, description: nil, status: nil)
    @board_id = board_id
    @list_id = list_id
    @task_id = task_id
    @name = name
    @description = description
    @status = status

    Trello.configure do |config|
      config.developer_public_key = ENV['TRELLO_PUBLIC_KEY']
      config.member_token = ENV['TRELLO_MEMBER_TOKEN']
    end
  end

  def call
    card = Trello::Card.find(@task_id)
    update_card(card)
    Sublayer.configuration.logger.log(:info, "Trello task updated successfully: ", card.short_id)
    "Trello task updated with ID: #{card.short_id}"
  rescue Trello::Error => e
    error_message = "Error updating Trello task: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def update_card(card)
    card.name = @name if @name
    card.description = @description if @description
    if @status
      target_list = Trello::List.find(@list_id)
      card.list_id = target_list.id if target_list
    end
    card.save
  end
end