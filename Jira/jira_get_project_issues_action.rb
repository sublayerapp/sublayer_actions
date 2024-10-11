require 'jira-ruby'

# Description: Sublayer::Action responsible for retrieving a list of issues from a Jira project's backlog.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with a project_key to identify the Jira project.
# It returns an array of issue keys (strings) found in the project's backlog.
#
# Example usage: When you need to retrieve a list of backlogged issues for processing or analysis within a Sublayer workflow.

class JiraGetProjectIssuesAction < Sublayer::Actions::Base
  def initialize(project_key:)
    @project_key = project_key
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
      issues = get_backlog_issues
      issue_keys = issues.map { |issue| issue.key }
      Sublayer.configuration.logger.log(:info, "Retrieved #{issue_keys.size} issues from Jira project backlog: #{@project_key}")
      return issue_keys
    rescue JIRA::HTTPError => e
      error_message = "Error retrieving Jira issues: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def get_backlog_issues
    jql = "project = #{@project_key} AND statusCategory = "Backlog""
    @client.Issue.jql(jql)
  end
end
