require 'jira-ruby'

# Description: Sublayer::Action responsible for transitioning a Jira issue from one status to another.
# This action facilitates the automation of Jira workflows by allowing AI-powered systems to move issues through their lifecycle stages.
#
# Requires: 'jira-ruby' gem
# $ gem install jira-ruby
# Or add `gem 'jira-ruby'` to your Gemfile
#
# It is initialized with the issue_key and transition_id.
# Example usage: Automating the movement of issues in a kanban board style workflow based on AI insights.
class JiraTransitionIssueAction < Sublayer::Actions::Base
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
      transitions = issue.transitions.all.map { |t| { id: t.id, name: t.name } }

      if transitions.any? { |t| t[:id] == @transition_id }
        issue.transition(transition: { id: @transition_id })
        Sublayer.configuration.logger.log(:info, "Successfully transitioned Jira issue #{@issue_key} using transition ID #{@transition_id}")
        true
      else
        error_message = "Transition ID #{@transition_id} is not valid for Jira issue #{@issue_key}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue JIRA::HTTPError => e
      error_message = "Error transitioning Jira issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
