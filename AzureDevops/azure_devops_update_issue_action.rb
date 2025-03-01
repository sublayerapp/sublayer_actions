require 'httparty'

# Description: Sublayer::Action responsible for updating an existing issue in Azure DevOps.
# This action integrates with Azure DevOps using the REST API and HTTParty.
#
# It is initialized with the organization, project, issue_id, and a hash of fields to update.
# It returns the ID of the updated issue.
#
# Example usage: When you want to update an issue in Azure DevOps based on AI-generated insights or project requirements.

class AzureDevopsUpdateIssueAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(organization:, project:, issue_id:, fields: {})
    @organization = organization
    @project = project
    @issue_id = issue_id
    @fields = fields
    @personal_access_token = ENV['AZURE_DEVOPS_PAT']
  end

  def call
    update_issue
  rescue HTTParty::Error => e
    error_message = "HTTP error during issue update: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error updating Azure DevOps issue: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def update_issue
    url = "https://dev.azure.com/#{@organization}/#{@project}/_apis/wit/workitems/#{@issue_id}?api-version=7.1"
    headers = {
      "Content-Type" => "application/json-patch+json",
      "Authorization" => "Basic #{Base64.strict_encode64(':' + @personal_access_token)}"
    }

    body = []
    @fields.each do |field, value|
      body << { "op" => "add", "path" => "/fields/System.#{field.to_s.split('_').collect(&:capitalize).join}", "value" => value }
    end

    response = self.class.patch(url, headers: headers, body: body.to_json)

    if response.success?
      issue_id = response.parsed_response['id']
      Sublayer.configuration.logger.log(:info, "Issue updated successfully in Azure DevOps with ID: #{issue_id}")
      issue_id
    else
      error_message = "Failed to update issue: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end