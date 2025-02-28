require 'httparty'

# Description: Sublayer::Action responsible for linking existing work items to an epic in Azure DevOps
# This action integrates with Azure DevOps using the REST API and HTTParty.
#
# It is initialized with the organization, project, epic_id, and an array of work_item_ids to be linked.
# It returns a confirmation message upon successful linking.
#
# Example usage: Useful for organizing tasks under a single epic for better project management.

class AzureDevopsLinkWorkItemToEpicAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(organization:, project:, epic_id:, work_item_ids:)
    @organization = organization
    @project = project
    @epic_id = epic_id
    @work_item_ids = work_item_ids
    @personal_access_token = ENV['AZURE_DEVOPS_PAT']
  end

  def call
    link_work_items_to_epic
  rescue HTTParty::Error => e
    error_message = "HTTP error during work item linking: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error linking work items to Azure DevOps epic: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def link_work_items_to_epic
    @work_item_ids.each do |work_item_id|
      url = "https://dev.azure.com/#{@organization}/#{@project}/_apis/wit/workitems/#{work_item_id}?api-version=7.1"
      headers = {
        "Content-Type" => "application/json-patch+json",
        "Authorization" => "Basic #{Base64.strict_encode64(':' + @personal_access_token)}"
      }

      body = [
        { "op" => "add", "path" => "/relations/-", "value" => { "rel" => "System.LinkTypes.Hierarchy-Forward", "url" => "https://dev.azure.com/#{@organization}/#{@project}/_apis/wit/workitems/#{@epic_id}" }}
      ]

      response = self.class.patch(url, headers: headers, body: body.to_json)

      unless response.success?
        error_message = "Failed to link work item #{work_item_id} to epic: HTTP #{response.code} - #{response.message}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    end

    confirmation_message = "Successfully linked work items to Epic ##{@epic_id}"
    Sublayer.configuration.logger.log(:info, confirmation_message)
    confirmation_message
  end
end