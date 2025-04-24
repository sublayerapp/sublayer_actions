class GithubTriggerWorkflowAction < GithubBase
  def initialize(repo:, workflow_id:)
    super(repo: repo)
    @workflow_id = workflow_id
  end

  def call
    begin
      @client.create_workflow_dispatch(@repo, @workflow_id)
      Sublayer.configuration.logger.log(:info, "Successfully triggered workflow \"#{@workflow_id}\" for repo \"#{@repo}\"")
    rescue Octokit::Error => e
      error_message = "Error triggering workflow: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end