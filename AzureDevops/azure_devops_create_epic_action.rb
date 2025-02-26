require 'httparty'

# Description: Sublayer::Action responsible for creating an epic in Azure DevOps.
# This action integrates with Azure DevOps using the REST API and HTTParty.
#
# It is initialized with the organization, project, epic_title, and optionally, description and area_path.
# It returns the ID of the created epic.
#
# Example usage: When you want to create a new epic in Azure DevOps based on AI-generated insights or project requirements.

class AzureDevopsCreateEpicAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(organization:, project:, epic_title:, description: '')
    @organization = organization
    @project = project
    @epic_title = epic_title
    @description = description
    @personal_access_token = ENV['AZURE_DEVOPS_PAT']
  end

  def call
    create_epic
  rescue HTTParty::Error => e
    error_message = "HTTP error during epic creation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error creating Azure DevOps epic: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def create_epic
    url = "https://dev.azure.com/#{@organization}/#{@project}/_apis/wit/workitems/$Epic?api-version=7.1"
    headers = {
      "Content-Type" => "application/json-patch+json",
      "Authorization" => "Basic #{Base64.strict_encode64(':' + @personal_access_token)}"
    }

    body = [
      { "op" => "add", "path" => "/fields/System.Title", "value" => @epic_title },
      { "op" => "add", "path" => "/fields/System.Description", "value" => @description }
    ]

    response = self.class.post(url, headers: headers, body: body.to_json)

    if response.success?
      epic_id = response.parsed_response['id']
      Sublayer.configuration.logger.log(:info, "Epic created successfully in Azure DevOps with ID: #{epic_id}")
      epic_id
    else
      error_message = "Failed to create epic: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
