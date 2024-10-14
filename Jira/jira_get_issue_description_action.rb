require 'jira-ruby'

# Description: Sublayer::Action responsible for retrieving the description of a specific Jira issue.
# This action allows for fetching additional context about an issue, which can be useful for analysis or further processing.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with the issue_key of the Jira issue.
# It returns the description of the Jira issue.
#
# Example usage: When you want to get the description of a Jira issue for use in an AI-driven workflow or analysis.

class JiraGetIssueDescriptionAction < Sublayer::Actions::Base
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
      description = issue.description
      Sublayer.configuration.logger.log(:info, "Successfully retrieved description for Jira issue #{@issue_key}")
      description
    rescue JIRA::HTTPError => e
      error_message = "Error fetching Jira issue description: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end