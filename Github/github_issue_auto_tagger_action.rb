# Description: Sublayer::Action responsible for automatically tagging GitHub issues based on analysis of the issue content.
# The action uses AI analysis to determine the most relevant labels, enhancing issue organization and prioritization.
#
# It is initialized with a repo and issue_number.
# It modifies the GitHub issue to add appropriate labels based on AI analysis.
#
# Example usage: When you want to automate the labeling process in your GitHub issues to improve workflow management and categorization.

class GithubIssueAutoTaggerAction < Sublayer::Actions::Base
  require 'openai'

  def initialize(repo:, issue_number:)
    @repo = repo
    @issue_number = issue_number
    @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
    @ai_client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    issue_content = fetch_issue_content
    labels = generate_labels(issue_content)
    add_labels_to_issue(labels)
  rescue Octokit::Error => e
    error_message = "GitHub API error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue OpenAI::Error => e
    error_message = "OpenAI error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error in GithubIssueAutoTaggerAction: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def fetch_issue_content
    issue = @client.issue(@repo, @issue_number)
    "#{issue.title}\n#{issue.body}"
  end

  def generate_labels(issue_content)
    response = @ai_client.completions(engine: 'text-davinci-002', parameters: {
      prompt: "Analyze the following issue content and suggest relevant GitHub labels:

#{issue_content}",
      max_tokens: 50
    })
    response['choices'].first['text'].split(',').map(&:strip)
  end

  def add_labels_to_issue(labels)
    @client.add_labels_to_an_issue(@repo, @issue_number, labels)
    Sublayer.configuration.logger.log(:info, "Labels added to issue #{@issue_number}: #{labels.join(', ')}")
  end
end
