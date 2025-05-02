require 'jira-ruby'

# Description: Sublayer::Action responsible for adding a comment to an existing Jira issue.
# This action allows for integration with Jira, a popular project management tool.
# It can be used to automatically add comments based on AI-generated insights or code analysis.
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
      Sublayer.configuration.logger.log(:info, "Jira comment created successfully: #{comment.id}")
      return comment
    rescue JIRA::HTTPError => e
      error_message = "Error creating Jira comment: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def add_comment
    issue = @client.Issue.find(@issue_key)
    comment = issue.comments.build
    comment.save(body: @comment_body)
    return comment
  end
end
