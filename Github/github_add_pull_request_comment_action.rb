class GithubAddPullRequestCommentAction < GithubBase
  def initialize(repo:, pull_number:, comment_body:)
    super(repo: repo)
    @pull_number = pull_number
    @comment_body = comment_body
  end

  def call
    begin
      @client.add_comment(@repo, @pull_number, @comment_body)
      Sublayer.configuration.logger.log(:info, "Successfully added comment to pull request \#{@pull_number} in #{@repo}")
    rescue Octokit::NotFound => e
      error_message = "Pull request not found: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error adding comment to pull request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end