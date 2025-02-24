require 'httparty'

# Description: Sublayer::Action responsible for creating an epic in Azure DevOps.
# This action uses the Azure DevOps REST API to create an epic work item in a specified project.
#
# Requires: 'httparty' gem
# $ gem install httparty
# Or add `gem 'httparty'` to your Gemfile
#
# It is initialized with:
# - organization: Azure DevOps organization name
# - project: Project name in Azure DevOps
# - title: Title of the epic
# - description: Optional description of the epic
# - area_path: Optional area path for the epic
# - iteration_path: Optional iteration path for the epic
#
# Returns the ID of the created epic.
#
# Example usage: When you want to create a new epic in Azure DevOps as part of an AI-driven 
# project management workflow or automated process.

class AzureDevopsCreateEpicAction < Sublayer::Actions::Base
  include HTTParty
  
  def initialize(organization:, project:, title:, description: nil, area_path: nil, iteration_path: nil)
    @organization = organization
    @project = project
    @title = title
    @description = description
    @area_path = area_path
    @iteration_path = iteration_path
    @pat = ENV['AZURE_DEVOPS_PAT']
    
    unless @pat
      raise StandardError, 'Azure DevOps Personal Access Token (PAT) not found in environment variables'
    end
  end

  def call
    begin
      response = create_epic
      epic_id = response['id']
      
      Sublayer.configuration.logger.log(:info, "Successfully created epic ##{epic_id} in Azure DevOps")
      epic_id
    rescue StandardError => e
      error_message = "Error creating epic in Azure DevOps: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_epic
    url = "https://dev.azure.com/#{@organization}/#{@project}/_apis/wit/workitems/$Epic?api-version=7.0"
    
    headers = {
      'Content-Type' => 'application/json-patch+json',
      'Authorization' => "Basic #{Base64.strict_encode64(":#{@pat}")}"
    }

    body = build_request_body

    response = HTTParty.post(
      url,
      headers: headers,
      body: body.to_json
    )

    unless response.success?
      raise StandardError, "API request failed with status #{response.code}: #{response.body}"
    end

    JSON.parse(response.body)
  end

  def build_request_body
    body = [
      {
        'op' => 'add',
        'path' => '/fields/System.Title',
        'value' => @title
      }
    ]

    if @description
      body << {
        'op' => 'add',
        'path' => '/fields/System.Description',
        'value' => @description
      }
    end

    if @area_path
      body << {
        'op' => 'add',
        'path' => '/fields/System.AreaPath',
        'value' => @area_path
      }
    end

    if @iteration_path
      body << {
        'op' => 'add',
        'path' => '/fields/System.IterationPath',
        'value' => @iteration_path
      }
    end

    body
  end
end