require 'jira-ruby'

# Description: Sublayer::Action responsible for updating the status of a Jira issue.
# This action allows for automating workflow transitions based on AI analysis or external triggers.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with issue_key and new_status.
# It returns the updated Jira issue.
#
# Example usage: When you want to automatically update the status of a Jira issue based on AI-driven insights or automated processes.

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
      Sublayer.configuration.logger.log(:info, "Jira issue #{@issue_key} status updated to #{@new_status}")
      issue
    rescue JIRA::HTTPError => e
      error_message = "Error updating Jira issue status: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def update_status(issue)
    transitions = issue.transitions
    transition = transitions.find { |t| t.name.downcase == @new_status.downcase }

    if transition
      issue.transition!('transition' => { 'id' => transition.id })
    else
      error_message = "Status '#{@new_status}' not found in available transitions"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end