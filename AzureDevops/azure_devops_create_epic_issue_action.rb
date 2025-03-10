require 'httparty'

# Description: Sublayer::Action responsible for creating an issue within an existing epic in Azure DevOps.
# This action integrates with Azure DevOps using the REST API and HTTParty.
#
# It is initialized with the organization, project, epic_id, issue_title, and optionally, description and area_path.
# It returns the ID of the created issue.
#
# Example usage: When you want to add new issues to an epic in Azure DevOps based on AI-generated insights or project requirements.

class AzureDevopsCreateEpicIssueAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(organization:, project:, epic_id:, issue_title:, description: '')
    @organization = organization
    @project = project
    @epic_id = epic_id
    @issue_title = issue_title
    @description = description
    @personal_access_token = ENV['AZURE_DEVOPS_PAT']
  end

  def call
    create_issue_within_epic
  rescue HTTParty::Error => e
    error_message = "HTTP error during issue creation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error creating Azure DevOps issue: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def create_issue_within_epic
    url = "https://dev.azure.com/#{@organization}/#{@project}/_apis/wit/workitems/$Issue?api-version=7.1"
    headers = {
      "Content-Type" => "application/json-patch+json",
      "Authorization" => "Basic #{Base64.strict_encode64(':' + @personal_access_token)}"
    }

    body = [
      { "op" => "add", "path" => "/fields/System.Title", "value" => @issue_title },
      { "op" => "add", "path" => "/fields/System.Description", "value" => @description },
      { "op" => "add", "path" => "/relations/-", "value" => { "rel" => "System.LinkTypes.Hierarchy-Reverse", "url" => "https://dev.azure.com/#{@organization}/#{@project}/_apis/wit/workitems/#{@epic_id}" }}
    ]

    response = self.class.post(url, headers: headers, body: body.to_json)

    if response.success?
      issue_id = response.parsed_response['id']
      Sublayer.configuration.logger.log(:info, "Issue created successfully in Azure DevOps with ID: #{issue_id}")
      issue_id
    else
      error_message = "Failed to create issue: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
