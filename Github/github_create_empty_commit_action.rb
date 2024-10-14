require 'octokit'

# Description: Sublayer::Action responsible for creating an empty commit on a specified branch in a GitHub repository.
# This action can be useful for triggering CI/CD pipelines, refreshing GitHub Pages, or creating placeholder commits.
#
# It is initialized with a repo, branch, and commit message.
# It returns the SHA of the new commit.
#
# Example usage: When you want to create an empty commit to trigger a GitHub action or refresh a deployment.

class GithubCreateEmptyCommitAction < Sublayer::Actions::Base
  def initialize(repo:, branch:, commit_message:)
    @repo = repo
    @branch = branch
    @commit_message = commit_message
    @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def call
    begin
      # Get the latest commit on the branch
      latest_commit = @client.ref(@repo, "heads/#{@branch}")
      base_tree = @client.commit(@repo, latest_commit.object.sha).commit.tree.sha

      # Create a new tree with no changes
      new_tree = @client.create_tree(@repo, [], base_tree: base_tree)

      # Create a new commit
      new_commit = @client.create_commit(@repo, @commit_message, new_tree.sha, latest_commit.object.sha)

      # Update the reference of the branch to point to the new commit
      @client.update_ref(@repo, "heads/#{@branch}", new_commit.sha)

      Sublayer.configuration.logger.log(:info, "Empty commit created successfully on #{@branch} in #{@repo}")
      new_commit.sha
    rescue Octokit::Error => e
      error_message = "Error creating empty commit: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end