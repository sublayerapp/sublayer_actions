# Description: Sublayer::Action responsible for retrieving a list of open issues from a specified GitHub repository.
# This action can be used to integrate issue tracking into AI workflows, enabling automated reporting or analysis.
#
# It is initialized with a repo and optionally a state (open/closed/all) and labels for filtering issues.
# It returns a list of issues with their titles and URLs.
#
# Example usage: Use this action to fetch open issues from a GitHub repository and process them in an AI workflow.

class GithubListIssuesAction < Sublayer::Actions::Base
  def initialize(repo:, state: 'open', labels: [])
    @repo = repo
    @state = state
    @labels = labels
    @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def call
    begin
      fetch_issues
    rescue Octokit::Error => e
      error_message = "Error fetching GitHub issues: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
  
  private

  def fetch_issues
    options = {
      state: @state,
      labels: @labels.join(','),
      per_page: 100 # Fetch up to 100 issues per page
    }
    
    issues = @client.issues(@repo, options)
    Sublayer.configuration.logger.log(:info, "Fetched #{issues.size} issues from repository #{@repo}")
    issues.map { |issue| {title: issue.title, url: issue.html_url} }
  end
end
