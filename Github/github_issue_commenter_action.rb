# Description: Sublayer::Action responsible for posting comments on GitHub issues.
# This action is useful for automated feedback or updates from CI pipelines or other processes.
#
# It is initialized with a repo, issue_number, and comment, and it returns the comment URL upon success.
#
# Example usage: Automatically comment on issues after a CI pipeline has completed, providing status or results.

class GithubIssueCommenterAction < Sublayer::Actions::Base
  def initialize(repo:, issue_number:, comment:)
    @repo = repo
    @issue_number = issue_number
    @comment = comment
    @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def call
    begin
      response = @client.add_comment(@repo, @issue_number, @comment)
      Sublayer.configuration.logger.log(:info, "Comment posted successfully to issue ##{@issue_number} in repo #{@repo}")
      response.html_url
    rescue Octokit::NotFound => e
      error_message = "Issue not found: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Octokit::Error => e
      error_message = "Error posting comment: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
