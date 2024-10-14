class GithubCreateEmptyCommitAction < GithubBase
  def initialize(repo:, branch:, commit_message: "Empty commit")
    super(repo: repo)
    @branch = branch
    @commit_message = commit_message
  end

  def call
    begin
      base_sha = @client.ref(@repo, "heads/#{@branch}").object.sha
      @client.create_commit(@repo, @commit_message, base_sha, [], {
        author: { name: 'Sublayer AI', email: 'sublayer@example.com' },
        committer: { name: 'Sublayer AI', email: 'sublayer@example.com' }
      })
      Sublayer.configuration.logger.log(:info, "Created empty commit on branch #{@branch} of #{@repo}")
    rescue Octokit::UnprocessableEntity => e
      error_message = "Error creating empty commit: #{e.message}. Check if the branch already exists and if the commit message is valid."
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end