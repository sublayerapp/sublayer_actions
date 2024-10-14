# Description: Sublayer::Action responsible for creating an empty commit on a specified branch in a GitHub repository.
# This action allows integration with GitHub to perform automated actions like triggering CI/CD pipelines without modifying the code or content.
#
# It is initialized with repo, branch, and commit_message. It returns the commit URL.
#
# Example usage: When you want to trigger workflows configured to run on commit without changing any files.

class GithubCreateEmptyCommitAction < GithubBase
  def initialize(repo:, branch:, commit_message: "Empty commit")
    super(repo: repo)
    @branch = branch
    @commit_message = commit_message
  end

  def call
    begin
      latest_commit = @client.ref(@repo, "heads/#{@branch}").object.sha
      @client.create_commit(@repo, @commit_message, latest_commit, latest_commit)
      ref = @client.update_ref(@repo, "heads/#{@branch}", latest_commit)
      commit_url = ref.object.url
      Sublayer.configuration.logger.log(:info, "Empty commit created successfully on branch #{@branch}: #{commit_url}")
      commit_url
    rescue Octokit::Error => e
      error_message = "Error creating empty commit: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
