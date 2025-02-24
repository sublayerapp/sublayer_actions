require 'httparty'

# Description: Sublayer::Action responsible for creating an epic in Azure DevOps using the REST API.
# This action enables programmatic creation of epics in Azure DevOps projects, which can be useful
# for automating project management tasks or creating epics based on AI-generated insights.
#
# Requires: 'httparty' gem
# $ gem install httparty
# Or add `gem 'httparty'` to your Gemfile
#
# It is initialized with organization, project, title, and optional description and other fields.
# It returns the ID of the created epic work item.
#
# Environment variables required:
# - AZURE_DEVOPS_PAT: Personal Access Token for Azure DevOps
#
# Example usage: When you want to automatically create epics in Azure DevOps based on
# AI-generated project planning or requirements analysis.

class AzureDevopsCreateEpicAction < Sublayer::Actions::Base
  include HTTParty
  
  def initialize(organization:, project:, title:, description: nil, area_path: nil, iteration_path: nil)
    @organization = organization
    @project = project
    @title = title
    @description = description
    @area_path = area_path
    @iteration_path = iteration_path
    @base_url = "https://dev.azure.com/#{@organization}/#{@project}/_apis/wit/workitems/$Epic?api-version=7.0"
    @headers = {
      'Content-Type' => 'application/json-patch+json',
      'Authorization' => "Basic #{Base64.strict_encode64(':' + ENV['AZURE_DEVOPS_PAT'])}"
    }
  end

  def call
    begin
      response = create_epic
      
      if response.success?
        epic_id = response['id']
        Sublayer.configuration.logger.log(:info, "Successfully created epic with ID: #{epic_id}")
        epic_id
      else
        error_message = "Failed to create epic. Status: #{response.code}, Message: #{response.body}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      error_message = "Error creating epic in Azure DevOps: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def create_epic
    body = build_request_body
    
    self.class.post(
      @base_url,
      headers: @headers,
      body: body.to_json
    )
  end

  def build_request_body
    body = [
      {
        "op": "add",
        "path": "/fields/System.Title",
        "value": @title
      }
    ]

    if @description
      body << {
        "op": "add",
        "path": "/fields/System.Description",
        "value": @description
      }
    end

    if @area_path
      body << {
        "op": "add",
        "path": "/fields/System.AreaPath",
        "value": @area_path
      }
    end

    if @iteration_path
      body << {
        "op": "add",
        "path": "/fields/System.IterationPath",
        "value": @iteration_path
      }
    end

    body
  end
end