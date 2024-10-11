require 'jira-ruby'

# Description: Sublayer::Action responsible for retrieving a list of issues from a Jira project's backlog.
# This action allows for integration with Jira, a popular project management tool.
# It can be used to fetch issues for analysis, reporting, or further processing in AI-driven workflows.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with a project_key and optional parameters for filtering and sorting.
# It returns an array of Jira issues from the project's backlog.
#
# Example usage: When you want to analyze or process issues in a Jira project's backlog as part of an AI workflow.

class JiraGetProjectIssuesAction < Sublayer::Actions::Base
  def initialize(project_key:, max_results: 50, start_at: 0, jql_filter: nil)
    @project_key = project_key
    @max_results = max_results
    @start_at = start_at
    @jql_filter = "project = #{@project_key}"
    @jql_filter = @jql_filter + " && " +jql_filter if jql_filter
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
      Sublayer.configuration.logger.log(:info, "Successfully retrieved #{issues.count} issues from Jira project #{@project_key}")
      issues
    rescue JIRA::HTTPError => e
      error_message = "Error fetching Jira issues: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def fetch_issues
    options = {
      max_results: @max_results,
      start_at: @start_at,
      fields: [:key, :summary, :status, :issuetype, :priority, :created, :updated],
      validate_query: true
    }

    @client.Issue.jql(@jql_filter, options)
  end
end
