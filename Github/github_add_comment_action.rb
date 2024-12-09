class GithubAddCommentAction < GithubBase
  def initialize(repo:, issue_number:, comment:)
    super(repo: repo)
    @issue_number = issue_number
    @comment = comment
  end

  def call
    begin
      @client.add_comment(@repo, @issue_number, @comment)
      Sublayer.configuration.logger.log(:info, "Comment added successfully to issue/PR #{@issue_number} in #{@repo}")
    rescue Octokit::Error => e
      error_message = "Error adding comment: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end