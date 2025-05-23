# Description: Sublayer::Action responsible for creating an issue in a GitHub repository.
# This action automates the process of issue creation, which can be useful for project management tasks.
#
# It is initialized with a repository name, title, and body of the issue, and optionally labels and assignees.
# It returns the URL of the created issue.
#
# Example usage: When you want to create GitHub issues based on AI-generated insights or automated processes.

class GithubCreateIssueAction < Sublayer::Actions::Base
  def initialize(repo:, title:, body:, labels: [], assignees: [])
    @repo = repo
    @title = title
    @body = body
    @labels = labels
    @assignees = assignees
    @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def call
    begin
      options = { labels: @labels, assignees: @assignees }
      issue = @client.create_issue(@repo, @title, @body, options)
      Sublayer.configuration.logger.log(:info, "GitHub issue created successfully: #{issue.html_url}")
      issue.html_url
    rescue Octokit::Error => e
      error_message = "Error creating GitHub issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end