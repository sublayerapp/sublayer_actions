class GithubAddCommentToPRAction < GithubBase
  def initialize(repo:, pr_number:, comment_body:)
    super(repo: repo)
    @pr_number = pr_number
    @comment_body = comment_body
  end

  def call
    begin
      @client.add_comment(@repo, @pr_number, @comment_body)
      Sublayer.configuration.logger.log(:info, "Comment added successfully to PR #{@pr_number} in #{@repo}")
    rescue Octokit::NotFound => e
      error_message = "PR not found: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error adding comment to PR: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end