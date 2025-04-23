require 'jira-ruby'

# Description: Sublayer::Action responsible for updating the status of a Jira issue.
# This action allows for integration with Jira, a popular project management tool.
# It can be used to automatically transition issues based on AI-generated insights or code analysis.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with the issue_key and the desired transition_id. Please use a Jira action to get available transitions, or inspect your Jira instance manually.
# It returns the updated Jira issue.
#
# Example usage: When you want to change the status of a Jira issue based on AI-generated insights or automated processes.

class JiraUpdateIssueStatusAction < Sublayer::Actions::Base
  def initialize(issue_key:, transition_id:)
    @issue_key = issue_key
    @transition_id = transition_id
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
      issue.transitions.build.save!('transition' => { 'id' => @transition_id })
      updated_issue = @client.Issue.find(@issue_key) #refetch for updated data
      Sublayer.configuration.logger.log(:info, "Successfully updated status for Jira issue #{@issue_key} to transition id #{@transition_id}")
      updated_issue
    rescue JIRA::HTTPError => e
      error_message = "Error updating Jira issue status: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end