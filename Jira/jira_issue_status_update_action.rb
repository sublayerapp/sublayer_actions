require 'jira-ruby'

# Description: Sublayer::Action responsible for updating the status of an existing Jira issue.
# This action allows AI-driven workflows to automate task progression through different statuses in Jira.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with issue_key and status_name.
# It updates the status of the specified Jira issue and logs the operation.
#
# Example usage: When an AI workflow determines that a task is complete, it can automatically move the Jira issue to 'Done'.

class JiraIssueStatusUpdateAction < Sublayer::Actions::Base
  def initialize(issue_key:, status_name:)
    @issue_key = issue_key
    @status_name = status_name
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
      update_status
      Sublayer.configuration.logger.log(:info, "Successfully updated status for Jira issue #{@issue_key} to #{@status_name}")
    rescue JIRA::HTTPError => e
      error_message = "Error updating Jira issue status: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def update_status
    issue = @client.Issue.find(@issue_key)
    transitions = issue.transitions.all
    transition = transitions.find { |t| t.name.downcase == @status_name.downcase }
    if transition
      issue.transitions.build.save(transition: { id: transition.id })
    else
      raise StandardError, "Transition to status '#{@status_name}' not found for this issue."
    end
  end
end