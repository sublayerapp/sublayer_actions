class GithubCheckWorkflowRunStatusAction < GithubBase
  def initialize(repo:, run_id:)
    super(repo: repo)
    @run_id = run_id
  end

  def call
    begin
      response = @client.workflow_run(@repo, @run_id)

      status = response.status
      conclusion = response.conclusion

      # Log the status and conclusion
      Sublayer.configuration.logger.log(:info, "Workflow run status: #{status}")
      Sublayer.configuration.logger.log(:info, "Workflow run conclusion: #{conclusion}")

      # Return a hash containing the status and conclusion
      { status: status, conclusion: conclusion }
    rescue Octokit::NotFound => e
      error_message = "Workflow run not found: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error checking workflow run status: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end