class GithubAddCommentToPRAction < GithubBase
  def initialize(repo:, pr_number:, comment:)
    super(repo: repo)
    @pr_number = pr_number
    @comment = comment
  end

  def call
    begin
      @client.add_comment(@repo, @pr_number, @comment)
      Sublayer.configuration.logger.log(:info, "Comment added successfully to PR #{@pr_number}")
    rescue Octokit::Error => e
      error_message = "Error adding comment to PR: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end