# Description: Sublayer::Action responsible for creating an Epic in Azure Devops.
# This action allows for integration with Azure Devops, a popular project management tool.
# It can be used to automatically create Epics based on AI-generated insights or code analysis.
#
# Requires: 'azure-devops' gem
# $ gem install azure-devops
# Or add `gem 'azure-devops'` to your Gemfile
#
# It is initialized with organization, project, name, and an optional description.
# It returns the id of the created Azure Devops Epic.
#
# Example usage: When you want to create an Epic in Azure Devops based on AI-generated insights or automated processes.

class AzureDevopsCreateEpicAction < Sublayer::Actions::Base
  def initialize(organization:, project:, name:, description: nil)
    @organization = organization
    @project = project
    @name = name
    @description = description

    # Initialize Azure DevOps client
    @client = AzureDevops::Client.new(access_token: ENV['AZURE_DEVOPS_ACCESS_TOKEN'])
  end

  def call
    begin
      # Create the epic
      epic = create_epic
      Sublayer.configuration.logger.log(:info, "Azure Devops Epic created successfully: #{epic.id}")
      return epic.id
    rescue AzureDevops::Error => e
      error_message = "Error creating Azure Devops Epic: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_epic
    work_item_tracking_client = @client.work_item_tracking_client
    epic_params = {
      'op' => 'add',
      'path' => '/fields/System.Title',
      'value' => @name
    }
    if @description
      epic_params_description = {
        'op' => 'add',
        'path' => '/fields/System.Description',
        'value' => @description
      }
      epic_params = [epic_params,epic_params_description]       
    else
      epic_params = [epic_params]     
    end
    work_item_tracking_client.create_work_item(@project, epic_params, 'Epic',@organization)
  end
end