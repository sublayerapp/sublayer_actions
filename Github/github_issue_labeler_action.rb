require 'octokit'

# Description: Sublayer::Action responsible for automatically labeling new GitHub issues
# based on their title and description using AI for analysis.
#
# This action can be used to automate issue triaging and improve issue management workflows.
#
# It is initialized with a repo, issue_number, and optional labels. It automatically computes
# and applies labels based on issue content.
#
# Example usage: When a new issue is created in a GitHub repository, use this action to apply 
# relevant labels to aid in categorization and prioritization.

class GithubIssueLabelerAction < Sublayer::Actions::Base
  def initialize(repo:, issue_number:)
    @repo = repo
    @issue_number = issue_number
    @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def call
    begin
      issue = @client.issue(@repo, @issue_number)
      labels = generate_labels(issue.title, issue.body)
      apply_labels(labels)
      Sublayer.configuration.logger.log(:info, "Successfully labeled issue ##{@issue_number} in #{@repo}")
    rescue Octokit::Error => e
      error_message = "Error labeling GitHub issue: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def generate_labels(title, description)
    # Placeholder: Implement AI model integration here to determine labels
    # Example: Analyze `title` and `description` with NLP model to suggest labels
    # For now, pretend it returns ['bug', 'enhancement'] as dummy labels
    ['bug', 'enhancement']
  end

  def apply_labels(labels)
    @client.add_labels_to_an_issue(@repo, @issue_number, labels)
  end
end
