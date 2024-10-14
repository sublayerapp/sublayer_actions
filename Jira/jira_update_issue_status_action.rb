require 'jira-ruby'

# Description: Sublayer::Action responsible for updating the status of a Jira issue.
# This action allows for automating workflow transitions based on AI analysis or external triggers,
# improving project management efficiency.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with the issue_key of the Jira issue and the new status.
# It returns the updated Jira issue object.
#
# Example usage: When you want to automatically update the status of a Jira issue
# based on AI-driven insights or automated processes.

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
      transition = find_transition(issue)
      
      if transition
        issue.transitions.build.save!('transition' => { 'id' => transition.id })
        Sublayer.configuration.logger.log(:info, "Successfully updated status of Jira issue #{@issue_key} to #{@new_status}")
        issue.reload
      else
        error_message = "No transition found for status: #{@new_status}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue JIRA::HTTPError => e
      error_message = "Error updating Jira issue status: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def find_transition(issue)
    issue.transitions.find { |t| t.to['name'].downcase == @new_status.downcase }
  end
end
