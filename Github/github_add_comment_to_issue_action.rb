class GithubAddCommentToIssueAction < GithubBase
  def initialize(repo:, issue_number:, comment_body:)
    super(repo: repo)
    @issue_number = issue_number
    @comment_body = comment_body
  end

  def call
    begin
      @client.add_comment(@repo, @issue_number, @comment_body)
      Sublayer.configuration.logger.log(:info, "Successfully added comment to issue \#{@issue_number} in repo \#{@repo}")
    rescue Octokit::NotFound => e
      error_message = "Issue not found: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Octokit::Error => e
      error_message = "Error adding comment to issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error adding comment: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end