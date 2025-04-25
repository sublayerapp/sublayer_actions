require 'httparty'

# Description: Sublayer::Action responsible for triggering a pipeline in Azure DevOps.
# This action integrates with Azure DevOps using the REST API and HTTParty.
#
# It is initialized with the organization, project, pipeline_id, and optionally, branch and parameters.
# It returns the number of the triggered pipeline run.
#
# Example usage: When you want to trigger a CI/CD pipeline in Azure DevOps automatically based on specific conditions or events.

class AzureDevopsTriggerPipelineAction < Sublayer::Actions::Base
  include HTTParty
  format :json

  def initialize(organization:, project:, pipeline_id:, branch: 'main', parameters: {})
    @organization = organization
    @project = project
    @pipeline_id = pipeline_id
    @branch = branch
    @parameters = parameters
    @personal_access_token = ENV['AZURE_DEVOPS_PAT']
  end

  def call
    trigger_pipeline
  rescue HTTParty::Error => e
    error_message = "HTTP error during pipeline trigger: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error triggering Azure DevOps pipeline: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def trigger_pipeline
    url = "https://dev.azure.com/#{@organization}/#{@project}/_apis/pipelines/#{@pipeline_id}/runs?api-version=7.1-preview.1"
    headers = {
      "Content-Type" => "application/json",
      "Authorization" => "Basic #{Base64.strict_encode64(':' + @personal_access_token)}"
    }

    body = {
      "resources" => {
        "repositories" => {
          "self" => {"refName" => "refs/heads/#{@branch}"}
        }
      },
      "templateParameters" => @parameters
    }

    response = self.class.post(url, headers: headers, body: body.to_json)

    if response.success?
      run_number = response.parsed_response['run']['id']
      Sublayer.configuration.logger.log(:info, "Pipeline triggered successfully in Azure DevOps with run number: #{run_number}")
      run_number
    else
      error_message = "Failed to trigger pipeline: HTTP #{response.code} - #{response.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
