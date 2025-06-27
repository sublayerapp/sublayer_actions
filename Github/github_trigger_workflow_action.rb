# Description: Sublayer::Action responsible for triggering GitHub workflows programmatically.
# This action is designed to enhance CI/CD integrations by allowing workflows to be triggered based on external events or conditions.
#
# It is initialized with a repo, ref (branch or commit SHA), and workflow_id, and can include additional inputs for the workflow.
# It returns the response from the GitHub API to verify that the workflow was triggered successfully.
#
# Example usage: When you want to programmatically trigger a CI/CD pipeline in GitHub after certain conditions are met in your AI processes.

class GithubTriggerWorkflowAction < Sublayer::Actions::Base
  def initialize(repo:, ref:, workflow_id:, inputs: {})
    @repo = repo
    @ref = ref
    @workflow_id = workflow_id
    @inputs = inputs
    @client = Octokit::Client.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])
  end

  def call
    trigger_workflow
  rescue Octokit::Error => e
    error_message = "Error triggering GitHub workflow: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def trigger_workflow
    response = @client.workflow_run(@repo, @workflow_id, { ref: @ref, inputs: @inputs })
    if response
      Sublayer.configuration.logger.log(:info, "Workflow triggered successfully for #{@repo} on ref #{@ref}")
      response
    else
      error_message = "Failed to trigger workflow for #{@repo} on ref #{@ref}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
