require 'httparty'

# Description: Sublayer::Action responsible for creating an epic in Azure DevOps using their REST API.
# This action allows for the integration with Azure DevOps to manage project planning at a higher level by creating epics.
#
# It is initialized with an organization, project, personal_access_token, title, and optionally description and extra_fields.
# It returns the ID of the created epic in Azure DevOps.
#
# Example usage: When you want to create an epic in Azure DevOps as part of an AI-driven workflow or project management integration.

class AzureDevopsCreateEpicAction < Sublayer::Actions::Base
  include HTTParty
  base_uri 'dev.azure.com'

  def initialize(organization:, project:, personal_access_token:, title:, description: nil, extra_fields: {})
    @organization = organization
    @project = project
    @auth = { username: '', password: personal_access_token }
    @title = title
    @description = description
    @extra_fields = extra_fields
  end

  def call
    response = create_epic
    if response.success?
      epic_id = response.parsed_response['id']
      Sublayer.configuration.logger.log(:info, "Epic created successfully in Azure DevOps with ID: \\#{epic_id}")
      epic_id
    else
      handle_error(response)
    end
  end

  private

  def create_epic
    url = "/#{@organization}/#{@project}/_apis/wit/workitems/$Epic?api-version=6.0"
    body = build_body

    options = {
      basic_auth: @auth,
      headers: { 'Content-Type' => 'application/json-patch+json' },
      body: body.to_json
    }

    self.class.post(url, options)
  end

  def build_body
    body = [
      { "op": "add", "path": "/fields/System.Title", "value": @title }
    ]
    body << { "op": "add", "path": "/fields/System.Description", "value": @description } if @description
    @extra_fields.each do |field, value|
      body << { "op": "add", "path": "/fields/#{field}", "value": value }
    end
    body
  end

  def handle_error(response)
    error_message = "Error creating Azure DevOps epic: \\\#{response.parsed_response['message']}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end