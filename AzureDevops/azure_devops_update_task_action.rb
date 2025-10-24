require 'httparty'

# Description: Sublayer::Action responsible for updating a task's status or attributes in Azure DevOps.
# This action integrates with Azure DevOps using the REST API and HTTParty.
#
# It is initialized with the organization, project, task_id, and a hash of updates to apply to the task.
# It allows updating the status or any other attributes specified in the hash.
#
# Example usage: Update task status based on insights or automate routine updates.

class AzureDevopsUpdateTaskAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(organization:, project:, task_id:, updates: {})
    @organization = organization
    @project = project
    @task_id = task_id
    @updates = updates
    @personal_access_token = ENV['AZURE_DEVOPS_PAT']
  end

  def call
    update_task
  rescue HTTParty::Error => e
    error_message = "HTTP error during task update: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error updating Azure DevOps task: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def update_task
    url = "https://dev.azure.com/#{@organization}/#{@project}/_apis/wit/workitems/#{@task_id}?api-version=7.1"
    headers = {
      "Content-Type" => "application/json-patch+json",
      "Authorization" => "Basic #{Base64.strict_encode64(':' + @personal_access_token)}"
    }

    body = @updates.map do |field, value|
      { "op" => "add", "path" => "/fields/#{field}", "value" => value }
    end

    response = self.class.patch(url, headers: headers, body: body.to_json)

    if response.success?
      task_id = response.parsed_response['id']
      Sublayer.configuration.logger.log(:info, "Task updated successfully in Azure DevOps with ID: #{task_id}")
      task_id
    else
      error_message = "Failed to update task: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
