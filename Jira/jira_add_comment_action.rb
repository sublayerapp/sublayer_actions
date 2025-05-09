require 'jira-ruby'

# Description: Sublayer::Action responsible for adding a comment to a Jira issue.
# This action allows for integration with Jira, enabling automated updates and communication within issue tracking workflows.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with the issue_key and the comment_body.
# It returns the id of the created Jira comment.
#
# Example usage: When you want to add a comment to a Jira issue based on AI-generated insights or automated processes.

class JiraAddCommentAction < Sublayer::Actions::Base
  def initialize(issue_key:, comment_body:)
    @issue_key = issue_key
    @comment_body = comment_body
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
      Sublayer.configuration.logger.log(:info, "Comment added successfully to Jira issue #{@issue_key}: #{comment.id}")
      return comment.id
    rescue JIRA::HTTPError => e
      error_message = "Error adding comment to Jira issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def add_comment
    issue = @client.Issue.find(@issue_key)
    issue.comments.build.save(body: @comment_body)
  end
end