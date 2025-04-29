class GithubAddCommentToPullRequestAction < GithubBase
  def initialize(repo:, pull_request_number:, comment_body:)
    super(repo: repo)
    @pull_request_number = pull_request_number
    @comment_body = comment_body
  end

  def call
    begin
      @client.add_comment(@repo, @pull_request_number, @comment_body)
    rescue Octokit::NotFound => e
      error_message = "Pull request not found: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Octokit::Error => e
      error_message = "Error creating a comment: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end