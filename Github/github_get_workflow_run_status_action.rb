class GithubGetWorkflowRunStatusAction < GithubBase
  def initialize(repo:, run_id:)
    super(repo: repo)
    @run_id = run_id
  end

  def call
    begin
      run = @client.workflow_run(@repo, @run_id)
      Sublayer.configuration.logger.log(:info, "Retrieved workflow run status: #{run.status}")
      run.status
    rescue Octokit::NotFound => e
      error_message = "Workflow run not found: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error fetching workflow run status: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end