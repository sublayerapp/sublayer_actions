require 'notion-ruby-client'

# Description: Sublayer::Action responsible for updating the status of a task in Notion.
# This action monitors changes or inputs and automatically updates the task's progress or status field based on trigger conditions.
#
# It is initialized with a task_id and the new status value.
#
# Example usage: Automate the updating of task statuses in Notion when certain conditions are met, such as completing a related task.

class NotionUpdateTaskStatusAction < Sublayer::Actions::Base
  def initialize(task_id:, status:)
    @task_id = task_id
    @status = status
    @client = Notion::Client.new(token: ENV['NOTION_API_KEY'])
  end

  def call
    update_task_status
  rescue Notion::Errors::Error => e
    error_message = "Error updating task status in Notion: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Unexpected error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def update_task_status
    begin
      page = @client.update_page(@task_id, properties: {
        'Status' => {
          'select' => {
            'name' => @status
          }
        }
      })
      Sublayer.configuration.logger.log(:info, "Successfully updated task status for task #{@task_id}")
    rescue Notion::Errors::Error => e
      error_message = "Error updating task status: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end