require 'httparty'

# Description: Sublayer::Action responsible for retrieving all issues associated with a specific epic in Azure DevOps.
# This action integrates with Azure DevOps using the REST API and HTTParty.
#
# It is initialized with the organization, project, and epic_id.
# It returns an array of issues (work items) that are children of the specified epic.
#
# Example usage: When you want to analyze the progress of an epic, generate reports,
# or feed issue data into AI workflows for analysis or task planning.

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
    get_epic_issues
  rescue HTTParty::Error => e
    error_message = "HTTP error while fetching epic issues: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error fetching Azure DevOps epic issues: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def get_epic_issues
    # First, get the work item relations for the epic
    epic_url = "https://dev.azure.com/#{@organization}/#{@project}/_apis/wit/workitems/#{@epic_id}?$expand=relations&api-version=7.1"
    headers = {
      'Authorization' => "Basic #{Base64.strict_encode64(':' + @personal_access_token)}"
    }

    response = self.class.get(epic_url, headers: headers)

    unless response.success?
      error_message = "Failed to fetch epic details: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    # Filter for child work items
    child_relations = response.parsed_response['relations']&.select { |rel| rel['rel'] == 'System.LinkTypes.Hierarchy-Forward' } || []
    
    return [] if child_relations.empty?

    # Extract work item IDs from URLs
    child_ids = child_relations.map do |relation|
      relation['url'].split('/').last
    end

    # Batch get the work items
    work_items_url = "https://dev.azure.com/#{@organization}/#{@project}/_apis/wit/workitems?ids=#{child_ids.join(',')}&api-version=7.1"
    
    response = self.class.get(work_items_url, headers: headers)

    unless response.success?
      error_message = "Failed to fetch work items: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    issues = response.parsed_response['value'].map do |item|
      {
        id: item['id'],
        title: item['fields']['System.Title'],
        state: item['fields']['System.State'],
        type: item['fields']['System.WorkItemType'],
        description: item['fields']['System.Description'],
        created_date: item['fields']['System.CreatedDate'],
        changed_date: item['fields']['System.ChangedDate']
      }
    end

    Sublayer.configuration.logger.log(:info, "Successfully retrieved #{issues.length} issues for epic #{@epic_id}")
    issues
  end
end