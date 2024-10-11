require 'jira-ruby'

# Description: Sublayer::Action responsible for creating an issue in Jira.
# This action allows for integration with Jira, a popular project management tool.
# It can be used to automatically create tasks based on AI-generated insights or code analysis.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with project_key, issue_type, summary, and optional description and custom_fields.
# It returns the key of the created Jira issue.
#
# Example usage: When you want to create a Jira issue based on AI-generated insights or automated processes.

class JiraCreateIssueAction < Sublayer::Actions::Base
  def initialize(project_key:, issue_type:, summary:, description: nil, custom_fields: {})
    @project_key = project_key
    @issue_type = issue_type
    @summary = summary
    @description = description
    @custom_fields = custom_fields
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
      issue = create_issue
      Sublayer.configuration.logger.log(:info, "Jira issue created successfully: #{issue.id}")
      return issue
    rescue JIRA::HTTPError => e
      error_message = "Error creating Jira issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_issue
    issue = @client.Issue.build
    
    issue_params = {
      'fields' => {
        'project' => { 'key' => @project_key },
        'summary' => @summary,
        'issuetype' => { 'name' => @issue_type },
        'description' => @description
      }
    }

    @custom_fields.each do |field_id, value|
      issue_params['fields'][field_id] = value
    end

    issue.save(issue_params)
    return issue
  end
end
