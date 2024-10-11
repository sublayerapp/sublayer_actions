require 'jira-ruby'

# Description: A Sublayer::Action responsible for fetching a list of issues in a Jira project's backlog.
# This action is useful for monitoring project backlogs and generating reports or summaries based on project status.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with a project_key and optionally a query/filter for issues. It returns a list of issue keys in the backlog.
#
# Example usage: Use this action to retrieve all backlog issue keys for analysis or reporting.

class JiraGetProjectIssuesAction < Sublayer::Actions::Base
  def initialize(project_key:, jql_query: nil)
    @project_key = project_key
    @jql_query = jql_query || "project = #{@project_key} AND statusCategory = 'To Do'"
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
      issues = fetch_issues
      issue_keys = issues.map(&:key)
      Sublayer.configuration.logger.log(:info, "Fetched #{issue_keys.size} issues from Jira project #{@project_key}")
      issue_keys
    rescue JIRA::HTTPError => e
      error_message = "Error fetching Jira issues: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def fetch_issues
    @client.Issue.jql(@jql_query)
  end
end
