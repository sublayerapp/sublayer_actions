require 'httparty'

# Description: Sublayer::Action responsible for creating an epic in Azure DevOps.
# This action allows for integration with Azure DevOps, a popular project management tool.
# It can be used to automatically create epics based on AI-generated insights or code analysis.
#
# Requires: 'httparty' gem
# $ gem install httparty
# Or add `gem 'httparty' to your Gemfile
#
# It is initialized with organization_name, project_name, api_version, and an epic description.
# It returns the epic ID to verify it was created.
#
# Example usage: When you want to create an epic in Azure DevOps based on AI-generated insights or automated processes.

class AzureDevopsCreateEpicAction < Sublayer::Actions::Base
  include HTTParty

  def initialize(organization_name:, project_name:, api_version: '7.1', description:, access_token: nil)
    @organization_name = organization_name
    @project_name = project_name
    @api_version = api_version
    @description = description
    @access_token = access_token || ENV['AZURE_DEVOPS_ACCESS_TOKEN']
    @base_uri = "https://dev.azure.com/#{@organization_name}/#{@project_name}/_apis/wit/workitems/$Epic?api-version=#{@api_version}"
  end

  def call
    begin
      epic_id = create_epic
      Sublayer.configuration.logger.log(:info, "Azure DevOps epic created successfully: #{epic_id}")
      return epic_id
    rescue StandardError => e
      error_message = "Error creating Azure DevOps epic: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_epic
    headers = {
      'Content-Type' => 'application/json-patch+json',
      'Authorization' => "Basic " + Base64.encode64(":#{@access_token}").strip
    }

    body = [
      {
        "op": "add",
        "path": "/fields/System.Title",
        "value": @description[:title]
      },
      {
        "op": "add",
        "path": "/fields/System.Description",
        "value": @description[:description]
      }
    ].to_json

    response = self.class.patch(@base_uri, headers: headers, body: body)

    unless response.success?
      Sublayer.configuration.logger.log(:error, "Failed to create epic. Response: #{response.body}")
      raise StandardError, "Failed to create epic: #{response.message}"
    end

    JSON.parse(response.body)['id']
  end
end