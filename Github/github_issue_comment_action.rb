# Description: Sublayer::Action responsible for adding a comment to a specified issue in a GitHub repository.
# This action is useful for automation in workflows that involve code reviews or project management.
#
# It is initialized with a repo, issue_number, and comment_body.
# It adds the comment to the specified issue in the given repository.
#
# Example usage: Automatically adding comments to GitHub issues based on AI-generated insights or reviews.

class GithubIssueCommentAction < GithubBase
  def initialize(repo:, issue_number:, comment_body:)
    super(repo: repo)
    @issue_number = issue_number
    @comment_body = comment_body
  end

  def call
    begin
      @client.add_comment(@repo, @issue_number, @comment_body)
      Sublayer.configuration.logger.log(:info, "Comment added successfully to issue ##{@issue_number} in repo #{@repo}")
    rescue Octokit::Error => e
      error_message = "Error adding comment to GitHub issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end