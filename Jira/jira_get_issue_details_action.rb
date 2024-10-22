require 'jira-ruby'

# Description: Sublayer::Action responsible for retrieving details of a specific Jira issue.
# This action allows for integration with Jira, a popular project management tool.
# It can be used to fetch issue details for further processing or analysis in AI-driven workflows.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with an issue_key.
# It returns a hash containing the issue details.
#
# Example usage: When you need to retrieve Jira issue details for analysis or to include in an AI-generated report.

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
      issue = fetch_issue
      issue_details = extract_issue_details(issue)
      Sublayer.configuration.logger.log(:info, "Jira issue details retrieved successfully for issue: #{@issue_key}")
      return issue_details
    rescue JIRA::HTTPError => e
      error_message = "Error fetching Jira issue details: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def fetch_issue
    @client.Issue.find(@issue_key)
  end

  def extract_issue_details(issue)
    {
      key: issue.key,
      summary: issue.summary,
      description: issue.description,
      status: issue.status.name,
      issue_type: issue.issuetype.name,
      priority: issue.priority&.name,
      assignee: issue.assignee&.displayName,
      reporter: issue.reporter&.displayName,
      created_at: issue.created,
      updated_at: issue.updated,
      labels: issue.labels,
      components: issue.components.map(&:name),
      custom_fields: extract_custom_fields(issue)
    }
  end

  def extract_custom_fields(issue)
    custom_fields = {}
    issue.custom_field_keys.each do |field_key|
      custom_fields[field_key] = issue.customfield_value(field_key)
    end
    custom_fields
  end
end