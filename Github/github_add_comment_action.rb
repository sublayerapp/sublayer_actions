# Description: Sublayer::Action for adding a comment to a pull request or issue on Github.
# It leverages the Octokit gem for interacting with the Github API.
#
# Example usage:
# github_add_comment_action = GithubAddCommentAction.new(
#   repo: 'owner/repo',
#   issue_number: 123,
#   comment: 'This is a helpful comment'
# )
# result = github_add_comment_action.call

class GithubAddCommentAction < GithubBase
  def initialize(repo:, issue_number:, comment:)
    super(repo: repo)
    @issue_number = issue_number
    @comment = comment
  end

  def call
    begin
      @client.add_comment(@repo, @issue_number, @comment)
      Sublayer.configuration.logger.log(:info, "Comment added successfully to #{@repo}, issue #{@issue_number}")
    rescue Octokit::Error => e
      Sublayer.configuration.logger.log(:error, "Error adding comment: #{e.message}")
      raise e
    end
  end
end