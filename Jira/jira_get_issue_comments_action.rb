require 'jira-ruby'

# Description: Sublayer::Action responsible for fetching all comments for a specific Jira issue.
# This action allows integration with Jira to gather insights from team discussions or decisions
# documented in the comments section of an issue.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with the issue_key of the Jira issue.
# It returns an array of comments associated with the issue.
#
# Example usage: When you want to gather comments from a Jira issue for analysis or reporting in AI workflows.

class JiraGetIssueCommentsAction < Sublayer::Actions::Base
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
      comments = issue.comments.map(&:body)
      Sublayer.configuration.logger.log(:info, "Successfully retrieved comments for Jira issue #{@issue_key}")
      comments
    rescue JIRA::HTTPError => e
      error_message = "Error retrieving comments for Jira issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
