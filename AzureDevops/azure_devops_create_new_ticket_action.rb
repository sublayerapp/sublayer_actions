# Description: Sublayer::Action responsible for creating a new ticket in Azure DevOps.
# This action allows for integration with Azure DevOps, enabling automated ticket creation
# from AI-driven workflows. Uses the Azure DevOps API.
#
# It is initialized with organization, project, title, and optionally description.
# It returns the ID of the created ticket
#
# Example usage: Create Azure DevOps work items based on analysis of code or documentation

class AzureDevopsCreateNewTicketAction < Sublayer::Actions::Base
  def initialize(organization:, project:, title:, description: nil)
    @organization = organization
    @project = project
    @title = title
    @description = description
    @client = AzureDevops::Client.new(access_token: ENV['AZURE_DEVOPS_ACCESS_TOKEN'])
  end

  def call
    begin
      work_item = create_work_item
      Sublayer.configuration.logger.log(:info, "Azure DevOps work item created successfully: #{work_item.id}")
      return work_item.id
    rescue AzureDevops::Error => e
      error_message = "Error creating Azure DevOps work item: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_work_item
    @client.create_work_item(
      organization: @organization,
      project: @project,
      type: 'Bug', # You can change the work item type here
      title: @title,
      description: @description
    )
  end
end