# Description: Sublayer::Action responsible for creating a new ticket in Azure DevOps.
# It allows integration with Azure DevOps for project management.
#
# Requires: 'azure-devops' gem
# Ensure to have 'gem install azure-devops' or add `gem 'azure-devops'` to your Gemfile.
#
# It is initialized with organization, project, title, description, and optionally area path and iteration path.
# It logs the ticket creation and returns the ID of the created ticket.
#
# Example usage: When you want to automate ticket creation in Azure DevOps from AI-generated insights.

require 'azure_devops'

class AzureDevopsCreateTicketAction < Sublayer::Actions::Base
  def initialize(organization:, project:, title:, description:, area_path: nil, iteration_path: nil)
    @organization = organization
    @project = project
    @title = title
    @description = description
    @area_path = area_path
    @iteration_path = iteration_path
    @client = AzureDevOps::Client.new(access_token: ENV['AZURE_DEVOPS_TOKEN'])
  end

  def call
    begin
      work_item = create_ticket
      Sublayer.configuration.logger.log(:info, "Azure DevOps ticket created successfully: #{work_item.id}")
      work_item.id
    rescue AzureDevOps::Error => e
      error_message = "Error creating Azure DevOps ticket: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_ticket
    fields = {
      'System.Title' => @title,
      'System.Description' => @description
    }
    fields['System.AreaPath'] = @area_path if @area_path
    fields['System.IterationPath'] = @iteration_path if @iteration_path

    @client.create_work_item(
      organization: @organization,
      project: @project,
      type: 'Task',
      fields: fields
    )
  end
end