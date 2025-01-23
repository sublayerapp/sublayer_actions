# Description: Sublayer::Action responsible for adding a comment to an existing Jira issue.
# This action allows for integration with Jira, a popular project management tool.
# It can be used to automatically add comments to Jira tickets based on AI-generated insights, workflow updates, or other events.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with the issue_key and the comment text.
# It returns the ID of the created Jira comment.
#
# Example usage: When you want to update a Jira issue with a comment from an AI-driven workflow.

class JiraAddCommentAction < Sublayer::Actions::Base
  def initialize(issue_key:, comment:)
    @issue_key = issue_key
    @comment = comment
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
      comment = add_comment
      Sublayer.configuration.logger.log(:info, "Successfully added comment to Jira issue #{@issue_key}")
      comment.id
    rescue JIRA::HTTPError => e
      error_message = "Error adding comment to Jira issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def add_comment
    issue = @client.Issue.find(@issue_key)
    issue.add_comment(@comment)
  end
end