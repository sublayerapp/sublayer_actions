require 'jira-ruby'

# Description: Sublayer::Action responsible for updating the status of an existing Jira issue.
# This action allows for automating workflow transitions based on external events or AI-driven decisions,
# keeping Jira in sync with other systems or processes.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with issue_key and new_status.
# It returns the updated Jira issue object.
#
# Example usage: When you want to automatically update the status of a Jira issue based on AI-generated insights or automated processes.

class JiraUpdateIssueStatusAction < Sublayer::Actions::Base
  def initialize(issue_key:, new_status:)
    @issue_key = issue_key
    @new_status = new_status
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
      update_status(issue)
      Sublayer.configuration.logger.log(:info, "Jira issue #{@issue_key} status updated successfully to #{@new_status}")
      return issue
    rescue JIRA::HTTPError => e
      error_message = "Error updating Jira issue status: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def update_status(issue)
    transitions = issue.transitions
    transition = transitions.find { |t| t.to.name.downcase == @new_status.downcase }

    if transition
      issue.transition!(transition.id)
    else
      error_message = "No transition found to status: #{@new_status}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
