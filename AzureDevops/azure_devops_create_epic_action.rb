require 'httparty'

# Description: Sublayer::Action responsible for creating an epic in Azure DevOps.
# This action allows you to automatically create epics in your Azure DevOps project using the Azure DevOps REST API.
#
# Requires: httparty gem
# gem install httparty
#
# It is initialized with organization_url, project_name, api_version,  personal_access_token, and epic_title, and optional epic_description.
# It returns the ID of the created epic.
#
# Example usage: When you want to automatically create epics in Azure DevOps based on AI-driven insights or automated processes.

class AzureDevopsCreateEpicAction < Sublayer::Actions::Base
  include HTTParty

  def initialize(organization_url:, project_name:, api_version:, personal_access_token:, epic_title:, epic_description: nil)
    @organization_url = organization_url
    @project_name = project_name
    @api_version = api_version
    @personal_access_token = personal_access_token
    @epic_title = epic_title
    @epic_description = epic_description
    @base_uri = "\#{@organization_url}/\#{@project_name}/_apis/wit/workitems/$Epic?api-version="
  end

  def call
    begin
      epic_id = create_epic
      Sublayer.configuration.logger.log(:info, "Azure DevOps epic created successfully: \#{epic_id}")
      epic_id
    rescue StandardError => e
      error_message = "Error creating Azure DevOps epic: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_epic
    uri = URI(@base_uri + @api_version)

    headers = {
      'Content-Type' => 'application/json-patch+json',
      'Authorization' => "Basic \#{Base64.strict_encode64(':')}"
    }

    body = [
      {
        "op": "add",
        "path": "/fields/System.Title",
        "value": @epic_title
      }
    ]

    body << { "op": "add", "path": "/fields/System.Description", "value": @epic_description } if @epic_description

    response = HTTParty.patch(uri,
                              headers: headers,
                              body: body.to_json)

    unless response.success?
      Sublayer.configuration.logger.log(:error, "Failed to create Epic. Response: \#{response.body}")
      raise StandardError, "Failed to create Azure DevOps epic. Status code: \#{response.code}, Response: \#{response.body}"
    end

    JSON.parse(response.body)['id']
  end
end