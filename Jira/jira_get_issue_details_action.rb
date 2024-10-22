require 'jira-ruby'

# Description: Sublayer::Action to retrieve the details of a specific Jira issue.
# This action allows you to access information about a Jira issue within Sublayer workflows.
#
# Requires: 'jira-ruby' gem
# \$ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with an issue_key, representing the unique identifier of the Jira issue.
# It returns a hash containing the details of the Jira issue.
#
# Example usage: When you need to retrieve information about a specific Jira issue
# to make decisions or generate content within a Sublayer workflow.

class JiraGetIssueDetailsAction < Sublayer::Actions::Base
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
      Sublayer.configuration.logger.log(:info, "Jira issue details retrieved successfully for issue: #{@issue_key}")
      return issue.attrs
    rescue JIRA::HTTPError => e
      error_message = "Error retrieving Jira issue details for issue #{@issue_key}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end