require 'jira-ruby'

# Description: Sublayer::Action responsible for retrieving the status of a specific Jira issue.
# This action allows for checking the current state of an issue, which can be useful for monitoring progress and triggering actions based on status changes.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with the issue_key of the Jira issue.
# It returns the status of the Jira issue (e.g., 'In Progress', 'Done', 'Blocked').
#
# Example usage: When you want to track the progress of a Jira issue and perform different actions based on its status within a Sublayer workflow.

class JiraGetIssueStatusAction < Sublayer::Actions::Base
  def initialize(issue_key:)
    @issue_key = issue_key
    @client = JIRA::Client.new(
      username: ENV['JIRA_USERNAME'],
      password: ENV['JIRA_API_TOKEN'],
      site: ENV['JIRA_SITE'],
      context_path: '',
      auth_type: :basic
    )
  end

  def call
    begin
      issue = @client.Issue.find(@issue_key)
      status = issue.status.name
      Sublayer.configuration.logger.log(:info, "Successfully retrieved status for Jira issue #{@issue_key}: #{status}")
      status
    rescue JIRA::HTTPError => e
      error_message = "Error fetching Jira issue status: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
