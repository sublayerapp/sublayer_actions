# Description: Sublayer::Action responsible for creating an epic in Azure DevOps using their REST API.
# It can be used to automate the creation of epics based on AI insights or processes.
#
# Requires: 'rest-client' gem
# $ gem install rest-client
# Or add `gem 'rest-client'` to your Gemfile
#
# It is initialized with organization, project, title, and optionally description.
# It returns the ID of the created epic.
#
# Example usage: Automating the creation of a new epic in Azure DevOps to track AI-generated tasks or projects.

require 'rest-client'
require 'json'

class AzureDevopsCreateEpicAction < Sublayer::Actions::Base
  def initialize(organization:, project:, title:, description: nil)
    @organization = organization
    @project = project
    @title = title
    @description = description
    @personal_access_token = ENV['AZURE_DEVOPS_PAT']
    @base_url = "https://dev.azure.com/"
  end

  def call
    begin
      epic_id = create_epic
      Sublayer.configuration.logger.log(:info, "Azure DevOps epic created successfully: #{epic_id}")
      return epic_id
    rescue RestClient::ExceptionWithResponse => e
      handle_error(e)
    rescue StandardError => e
      error_message = "Unexpected error creating Azure DevOps epic: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_epic
    headers = {
      'Content-Type' => 'application/json',
      'Authorization' => "Basic #{Base64.strict_encode64(':' + @personal_access_token)}"
    }

    payload = {
      "fields": {
        "System.Title": @title,
        "System.Description": @description
      }
    }.to_json

    response = RestClient.post(
      create_epic_url,
      payload,
      headers
    )

    JSON.parse(response.body)['id']
  end

  def create_epic_url
    "#{@base_url}/#{@organization}/#{@project}/_apis/wit/workitems/$Epic?api-version=6.0"
  end

  def handle_error(error)
    error_message = "Failed to create Azure DevOps epic: #{error.http_code} - #{error.response}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end
