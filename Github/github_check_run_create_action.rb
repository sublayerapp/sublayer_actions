# Description: Sublayer::Action responsible for creating a check run in a GitHub repository for a specific commit.
# This is useful for CI/CD pipelines to report the status of checks/tests.
#
# It is initialized with a repo, head_sha (commit SHA), name of the check, and the status/conclusion.
# It returns the ID of the created check run or raises an error if creation fails.
#
# Example usage: When you want to create a check run in a GitHub repository for CI/CD purposes
to report on the success or failure of specific stages/tests.

class GithubCheckRunCreateAction < Sublayer::Actions::Base
  def initialize(repo:, head_sha:, name:, status:"queued", conclusion:nil, output: {})
    @repo = repo
    @head_sha = head_sha
    @name = name
    @status = status
    @conclusion = conclusion
    @output = output
    @client = Octokit::Client.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])
  end

  def call
    begin
      check_run = create_check_run
      Sublayer.configuration.logger.log(:info, "Check run created successfully in GitHub with ID: #{check_run.id}")
      return check_run.id
    rescue Octokit::Error => e
      error_message = "Error creating GitHub check run: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def create_check_run
    @client.create_check_run(
      @repo,
      @name,
      @head_sha,
      status: @status,
      conclusion: @conclusion,
      output: @output
    )
  end
end
