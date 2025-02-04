class GithubGetChangedFilesInPRAction < GithubBase
  def initialize(repo:, pr_number:)
    super(repo: repo)
    @pr_number = pr_number
  end

  def call
    begin
      pull_request = @client.pull_request(@repo, @pr_number)
      files_changed = pull_request.files.map(&:filename)
      Sublayer.configuration.logger.log(:info, "Successfully retrieved changed files for PR #{@pr_number} in repo #{@repo}")
      files_changed
    rescue Octokit::NotFound => e
      error_message = "Pull request not found: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error fetching changed files: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end