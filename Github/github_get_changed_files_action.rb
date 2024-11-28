class GithubGetChangedFilesAction < GithubBase
  def initialize(repo:, pr_number: nil, sha: nil)
    super(repo: repo)
    @pr_number = pr_number
    @sha = sha

    if @pr_number.nil? && @sha.nil?
      raise ArgumentError, "Either pr_number or sha must be provided"
    end
  end

  def call
    begin
      if @pr_number
        changed_files = @client.pull_request_files(@repo, @pr_number).map(&:filename)
      else
        comparison = @client.compare(@repo, @client.commit(@repo, @sha).parents[0].sha, @sha)
        changed_files = comparison.files.map(&:filename)
      end

      Sublayer.configuration.logger.log(:info, "Successfully retrieved changed files for repo: #{@repo}, pr_number: #{@pr_number}, sha: #{@sha}")
      changed_files
    rescue Octokit::NotFound => e
      error_message = "Resource not found: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error fetching changed files: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end