require 'restforce'

# Description: Sublayer::Action responsible for automating the creation, updating, and management of tasks within Salesforce CRM.
# This action allows for seamless integration of AI-driven insights into sales processes, providing a robust set of features
# for task management in Salesforce.
#
# It is initialized with Salesforce credentials, and optionally a task ID if updating a task.
# It supports creating a new task or updating an existing task with new data.
#
# Example usage: When you want to automatically generate tasks based on AI-generated insights and integrate them directly into Salesforce.

class SalesforceCRMTaskAutomationAction < Sublayer::Actions::Base
  def initialize(client_id:, client_secret:, username:, password:, security_token:, task_id: nil, task_data: {})
    @task_id = task_id
    @task_data = task_data
    @client = Restforce.new(
      username: username,
      password: password,
      security_token: security_token,
      client_id: client_id,
      client_secret: client_secret,
      api_version: '50.0'
    )
  end

  def call
    begin
      if @task_id.nil?
        create_task
      else
        update_task
      end
    rescue Restforce::ErrorCode => e
      error_message = "Salesforce API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error executing Salesforce task action: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def create_task
    task = @client.create('Task', @task_data)
    Sublayer.configuration.logger.log(:info, "Task created successfully with ID: #{task}")
    task
  end

  def update_task
    @client.update('Task', Id: @task_id, **@task_data)
    Sublayer.configuration.logger.log(:info, "Task updated successfully with ID: #{@task_id}")
    @task_id
  end
end