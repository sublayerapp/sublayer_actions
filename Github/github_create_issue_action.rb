# Description: Sublayer::Action responsible for creating a new issue in a GitHub repository.
# This action helps streamline issue tracking by automatically creating issues
# from generated problem descriptions or bug reports.
#
# It is initialized with a repository, title, body, and optional assignees and labels.
# It returns the URL of the created issue.
#
# Example usage: When you receive a problem description or bug report from
# an AI model and want to create an issue in a GitHub repository for tracking.

class GithubCreateIssueAction < Sublayer::Actions::Base
  def initialize(repo:, title:, body:, assignees: [], labels: [])
    @repo = repo
    @title = title
    @body = body
    @assignees = assignees
    @labels = labels
    @client = Octokit::Client.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])
  end

  def call
    begin
      issue = @client.create_issue(
        @repo,
        @title,
        @body,
        assignees: @assignees,
        labels: @labels
      )
      Sublayer.configuration.logger.log(:info, "Issue created successfully in GitHub repo #{@repo}: #{issue[:html_url]}")
      issue[:html_url]
    rescue Octokit::Error => e
      error_message = "Error creating GitHub issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
