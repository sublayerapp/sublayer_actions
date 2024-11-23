class GithubAddCommentToPullRequestAction < GithubBase
  def initialize(repo:, pull_request_number:, comment:)
    super(repo: repo)
    @pull_request_number = pull_request_number
    @comment = comment
  end

  def call
    begin
      @client.add_comment(@repo, @pull_request_number, @comment)
      Sublayer.configuration.logger.log(:info, "Comment added successfully to pull request #{@pull_request_number}")
    rescue Octokit::Error => e
      error_message = "Error adding comment to pull request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end