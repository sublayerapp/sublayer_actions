require 'jira-ruby'
require 'slack-ruby-client'

# Description: Sublayer::Action responsible for monitoring Jira issues by severity/criticality and sending notifications to Slack.
# This action helps teams respond quickly to critical issues by notifying them when such issues are found in a Jira project.
#
# It is initialized with project_key, severity, and Slack channel details.
# It scans Jira issues and sends a notification for critical issues.
#
# Example usage: Automate notifications for critical issues in Jira to improve response time and team awareness.

class JiraNotifyOnCriticalIssuesAction < Sublayer::Actions::Base
  def initialize(project_key:, severity:, slack_channel:, slack_token: nil)
    @project_key = project_key
    @severity = severity
    @slack_channel = slack_channel
    @slack_token = slack_token || ENV['SLACK_API_TOKEN']
    @jira_client = JIRA::Client.new(
      username: ENV['JIRA_USERNAME'],
      password: ENV['JIRA_API_TOKEN'],
      site: ENV['JIRA_SITE'],
      context_path: '',
      auth_type: :basic
    )
    @slack_client = Slack::Web::Client.new(token: @slack_token)
  end

  def call
    begin
      issues = fetch_critical_issues
      notify_slack(issues) unless issues.empty?
    rescue JIRA::HTTPError => e
      handle_error("Error fetching Jira issues: #{e.message}")
    rescue Slack::Web::Api::Errors::SlackError => e
      handle_error("Error sending Slack message: #{e.message}")
    rescue StandardError => e
      handle_error("Unexpected error: #{e.message}")
    end
  end

  private

  def fetch_critical_issues
    jql_query = "project = #{@project_key} AND severity >= #{@severity}"
    options = {
      fields: [:key, :summary, :priority, :severity],
      validate_query: true
    }
    
    @jira_client.Issue.jql(jql_query, options)
  end

  def notify_slack(issues)
    issues.each do |issue|
      message = "*Critical Issue Detected* \n#{issue.summary} \nPriority: #{issue.priority['name']} - Severity: #{issue.fields['severity']}"
      @slack_client.chat_postMessage(channel: @slack_channel, text: message)
      Sublayer.configuration.logger.log(:info, "Notified Slack about issue #{issue.key}")
    end
  end

  def handle_error(message)
    Sublayer.configuration.logger.log(:error, message)
    raise StandardError, message
  end
end
