class GithubGetFileContentsAction < GithubBase
  def initialize(repo:, branch: "main", file_path:)
    @repo = repo
    @branch = branch
    @file_path = file_path
    @client = Octokit::Client.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])
  end

  def call
    begin
      content = @client.contents(@repo, path: @file_path, ref: @branch)
      Base64.decode64(content.content)
    rescue Octokit::NotFound => e
      error_message = "File not found: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error fetching file contents: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
