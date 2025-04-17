require 'jira-ruby'

# Description: Sublayer::Action responsible for retrieving details of a specific Jira issue.
# This action can be used to fetch and utilize the information of an issue within workflows that integrate with Jira.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with an issue_key and returns the details of the Jira issue.
#
# Example usage: When you need to gather information from a Jira issue for decision-making or updating other systems.

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
      details = extract_details(issue)

      Sublayer.configuration.logger.log(:info, "Retrieved details for Jira issue: #{issue.key}")

      details
    rescue JIRA::HTTPError => e
      error_message = "Error retrieving Jira issue details: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Unexpected error: #{e.message}")
      raise e
    end
  end

  private

  def extract_details(issue)
    {
      key: issue.key,
      summary: issue.fields['summary'],
      description: issue.fields['description'],
      status: issue.fields['status']['name'],
      assignee: issue.fields['assignee'] ? issue.fields['assignee']['displayName'] : 'Unassigned',
      created_at: issue.fields['created'],
      updated_at: issue.fields['updated'],
    }
  end
end
