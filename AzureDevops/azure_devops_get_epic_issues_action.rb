require 'httparty'

# Description: Sublayer::Action responsible for fetching all issues within a specific epic in Azure DevOps.
# This action integrates with Azure DevOps using the REST API and HTTParty.
#
# It is initialized with the organization, project, and epic_id.
# It returns a list of issues for reporting, monitoring, or further automated processes.
#
# Example usage: When you want to gather all issues within an epic in Azure DevOps
# for reporting purposes or feeding into additional workflows.

class AzureDevopsGetEpicIssuesAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(organization:, project:, epic_id:)
    @organization = organization
    @project = project
    @epic_id = epic_id
    @personal_access_token = ENV['AZURE_DEVOPS_PAT']
  end

  def call
    fetch_issues_within_epic
  rescue HTTParty::Error => e
    error_message = "HTTP error during epic issues fetch: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error fetching Azure DevOps epic issues: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def fetch_issues_within_epic
    url = "https://dev.azure.com/#{@organization}/#{@project}/_apis/wit/wiql?api-version=7.1"
    headers = {
      "Content-Type" => "application/json",
      "Authorization" => "Basic #{Base64.strict_encode64(':' + @personal_access_token)}"
    }

    query = {
      "query" => "SELECT [System.Id], [System.WorkItemType], [System.Title], [System.State] FROM WorkItemLinks WHERE [Source].[System.TeamProject] = '#{@project}' AND [Source].[System.WorkItemType] = 'Epic' AND [Source].[System.Id] = #{@epic_id} AND [System.Links.LinkType] = 'Child' AND [Target].[System.WorkItemType] <> '' ORDER BY [System.Id]"
    }

    response = self.class.post(url, headers: headers, body: query.to_json)

    if response.success?
      work_items = response.parsed_response['workItemRelations'].map { |link| link['target'] }
      Sublayer.configuration.logger.log(:info, "Fetched #{work_items.size} issues related to epic #{@epic_id} in Azure DevOps.")
      work_items
    else
      error_message = "Failed to fetch epic issues: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
