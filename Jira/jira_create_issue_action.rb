require 'jira-ruby'

# Description: Sublayer::Action responsible for creating an issue in Jira.
# This action is valuable for development teams using AI to generate tasks or bug reports.
#
# It is initialized with project_key, issue_type, summary, and optionally description and custom_fields.
# It returns the key of the created Jira issue.
#
# Example usage: When an AI process identifies a new task or bug that needs to be tracked in Jira.

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
      site: ENV['JIRA_SITE_URL'],
      context_path: '',
      auth_type: :basic
    )
  end

  def call
    begin
      issue = @client.Issue.build
      issue.save({
        'fields' => {
          'project' => {'key' => @project_key},
          'summary' => @summary,
          'issuetype' => {'name' => @issue_type},
          'description' => @description
        }.merge(@custom_fields)
      })

      Sublayer.configuration.logger.log(:info, "Created Jira issue: #{issue.key}")
      issue.key
    rescue JIRA::HTTPError => e
      error_message = "Error creating Jira issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end