require 'jira-ruby'

# Description: Sublayer::Action responsible for updating existing issues in Jira with new information or status changes.
# This action allows automated processes to keep Jira projects up-to-date with progress or changes.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with issue_key and updates hash.
# It returns the updated Jira issue.
#
# Example usage: When an automated process has identified new information or a status change that needs to be reflected in a Jira issue.

class JiraUpdateIssueAction < Sublayer::Actions::Base
  def initialize(issue_key:, updates: {})
    @issue_key = issue_key
    @updates = updates
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
      update_issue(issue)
      Sublayer.configuration.logger.log(:info, "Jira issue updated successfully: #{@issue_key}")
      return issue
    rescue JIRA::HTTPError => e
      error_message = "Error updating Jira issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def update_issue(issue)
    issue.save({'fields' => @updates})
  end
end
