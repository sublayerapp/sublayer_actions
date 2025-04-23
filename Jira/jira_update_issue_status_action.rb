require 'jira-ruby'

# Description: Sublayer::Action responsible for updating the status of a Jira issue.
# This action allows for integration with Jira, enabling automated status updates based on AI-driven workflows.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with the issue_key and the desired new_status.
# It returns the updated Jira issue.
#
# Example usage: When you want to transition a Jira issue to a different state based on AI processing or analysis.

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
      available_transitions = issue.transitions.map { |t| t.to.name }

      if available_transitions.include?(@new_status)
        issue.transitions.build.save!('transition' => { 'id' => issue.transitions.find { |t| t.to.name == @new_status }.id })
        updated_issue = @client.Issue.find(@issue_key) # Fetch updated issue
        Sublayer.configuration.logger.log(:info, "Successfully updated Jira issue #{@issue_key} status to #{@new_status}")
        updated_issue
      else
        error_message = "Invalid transition to '#{@new_status}' for Jira issue #{@issue_key}. Available transitions: #{available_transitions.join(', ')}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue JIRA::HTTPError => e
      error_message = "Error updating Jira issue status: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end