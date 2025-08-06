require 'octokit'

# Description: Sublayer::Action responsible for creating a branch, committing changes, and opening a pull request against a GitHub repository.
# This action allows for fully autonomous pull request creation as part of an AI agent workflow.
#
# It is initialized with the repository name, base branch, head branch, commit message, file path, file content, PR title, and PR body.
# It returns the URL of the created pull request.
#
# Example usage: When you want to automate documentation updates or fix issues as part of an autonomous agent workflow.

class GithubFullyAutonomousPrAction < Sublayer::Actions::Base
  def initialize(repo:, base_branch:, head_branch:, commit_message:, file_path:, file_content:, pr_title:, pr_body:)
    @repo = repo
    @base_branch = base_branch
    @head_branch = head_branch
    @commit_message = commit_message
    @file_path = file_path
    @file_content = file_content
    @pr_title = pr_title
    @pr_body = pr_body
    @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end

  def call
    begin
      # 1. Create a new branch
      ref = @client.ref(@repo, "heads/#{@base_branch}")
      @client.create_ref(@repo, "refs/heads/#{@head_branch}", ref.object.sha)

      # 2. Create or update the file in the new branch
      begin
        content = @client.contents(@repo, path: @file_path, ref: @head_branch)
        sha = content.sha
        @client.update_contents(@repo, @file_path, @commit_message, sha, @file_content, branch: @head_branch)
      rescue Octokit::NotFound
        @client.create_contents(@repo, @file_path, @commit_message, @file_content, branch: @head_branch)
      end

      # 3. Create a pull request
      pr = @client.create_pull_request(@repo, @base_branch, @head_branch, @pr_title, @pr_body)

      Sublayer.configuration.logger.log(:info, "Successfully created pull request: #{pr.html_url}")
      pr.html_url
    rescue Octokit::Error => e
      error_message = "Error creating pull request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end