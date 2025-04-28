require 'jira-ruby'

# Description: Sublayer::Action responsible for transitioning a Jira issue from one status to another.
# This action automates workflow transitions in Jira, enabling smoother project management processes
# driven by predefined conditions or LLM-generated decisions.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with issue_key, transition_id, and an optional comment.
# It performs the transition, then logs and returns the transition status.
#
# Example usage: When you want to transition a Jira issue based on criteria evaluated by an AI.

class JiraWorkflowTransitionAction < Sublayer::Actions::Base
  def initialize(issue_key:, transition_id:, comment: nil)
    @issue_key = issue_key
    @transition_id = transition_id
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
      issue = @client.Issue.find(@issue_key)
      perform_transition(issue)
      Sublayer.configuration.logger.log(:info, "Transitioned Jira issue #{@issue_key} to #{@transition_id}")
      "Transition successful"
    rescue JIRA::HTTPError => e
      handle_error("Error transitioning Jira issue: #{e.message}", e)
    rescue StandardError => e
      handle_error("Unexpected error: #{e.message}", e)
    end
  end

  private

  def perform_transition(issue)
    issue.transitions.build.save('transition' => { 'id' => @transition_id })
    issue.comments.build.save(:body => @comment) if @comment
  end

  def handle_error(message, exception)
    Sublayer.configuration.logger.log(:error, message)
    raise StandardError, message
  end
end
