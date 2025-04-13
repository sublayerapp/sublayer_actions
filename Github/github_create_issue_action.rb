# Description: Sublayer::Action responsible for creating an issue in a GitHub repository.
# It fills and submits the issue data automatically, which is useful for bug tracking and feature requests based on AI insights.
#
# Example usage: When you want to create a new GitHub issue based on automatic AI-generated reports.

class GithubCreateIssueAction < Sublayer::Actions::Base
  def initialize(repo:, title:, body: nil, labels: [], assignees: [])
    @repo = repo
    @title = title
    @body = body
    @labels = labels
    @assignees = assignees
    @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def call
    begin
      issue = @client.create_issue(@repo, @title, @body, labels: @labels, assignees: @assignees)
      Sublayer.configuration.logger.log(:info, "GitHub issue created successfully: #{issue[:html_url]}")
      issue
    rescue Octokit::Error => e
      error_message = "Error creating GitHub issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
