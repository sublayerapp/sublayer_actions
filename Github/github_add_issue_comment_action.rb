require 'octokit'

# Description: Sublayer::Action responsible for adding comments to existing GitHub issues.
# This action allows AI agents to provide automated updates, analysis, or feedback on GitHub issues.
#
# It inherits from GithubBase which handles the Octokit client setup and authentication.
#
# It is initialized with:
# - repo: The repository in owner/repo format
# - issue_number: The number of the issue to comment on
# - comment: The content of the comment to add
#
# Example usage: When you want an AI agent to automatically provide analysis or updates
# on GitHub issues based on some automated process or LLM-generated content.

class GithubAddIssueCommentAction < GithubBase
  def initialize(repo:, issue_number:, comment:)
    super(repo: repo)
    @issue_number = issue_number
    @comment = comment
  end

  def call
    begin
      response = @client.add_comment(@repo, @issue_number, @comment)
      Sublayer.configuration.logger.log(:info, "Successfully added comment to issue ##{@issue_number} in #{@repo}")
      response.id
    rescue Octokit::NotFound => e
      error_message = "Issue not found: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Octokit::Unauthorized => e
      error_message = "Authentication error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error adding comment to issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end