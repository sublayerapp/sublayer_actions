require 'httparty'

# Description: Sublayer::Action responsible for retrieving detailed information about an epic in Azure DevOps.
# This action integrates with Azure DevOps using the REST API and HTTParty.
#
# It is initialized with the organization, project, and epic_id.
# It returns a hash containing the epic's details including title, description, state, and other metadata.
#
# Example usage: When you need to gather context about an epic before creating child items or for generating reports
# about epic status and progress.

class AzureDevopsGetEpicDetailsAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(organization:, project:, epic_id:)
    @organization = organization
    @project = project
    @epic_id = epic_id
    @personal_access_token = ENV['AZURE_DEVOPS_PAT']
  end

  def call
    get_epic_details
  rescue HTTParty::Error => e
    error_message = "HTTP error while fetching epic details: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error fetching Azure DevOps epic details: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def get_epic_details
    url = "https://dev.azure.com/#{@organization}/#{@project}/_apis/wit/workitems/#{@epic_id}?api-version=7.1&$expand=all"
    headers = {
      'Authorization' => "Basic #{Base64.strict_encode64(':' + @personal_access_token)}"
    }

    response = self.class.get(url, headers: headers)

    if response.success?
      epic_data = response.parsed_response
      formatted_data = {
        id: epic_data['id'],
        title: epic_data['fields']['System.Title'],
        description: epic_data['fields']['System.Description'],
        state: epic_data['fields']['System.State'],
        created_date: epic_data['fields']['System.CreatedDate'],
        created_by: epic_data['fields']['System.CreatedBy']['displayName'],
        assigned_to: epic_data['fields']['System.AssignedTo']&.dig('displayName'),
        priority: epic_data['fields']['Microsoft.VSTS.Common.Priority'],
        area_path: epic_data['fields']['System.AreaPath'],
        iteration_path: epic_data['fields']['System.IterationPath'],
        tags: epic_data['fields']['System.Tags']&.split(';')&.map(&:strip),
        url: epic_data['_links']['html']['href']
      }

      Sublayer.configuration.logger.log(:info, "Successfully retrieved epic details for ID: #{@epic_id}")
      formatted_data
    else
      error_message = "Failed to fetch epic details: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end