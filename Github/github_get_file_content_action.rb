class GithubGetFileContentAction < GithubBase
  def initialize(repo:, file_path:, branch: 'main')
    super(repo: repo)
    @file_path = file_path
    @branch = branch
  end

  def call
    begin
      file_content = @client.contents(@repo, path: @file_path, ref: @branch).content
      Sublayer.configuration.logger.log(:info, "Successfully retrieved content for file #{@file_path} from repository #{@repo}")
      Base64.decode64(file_content)
    rescue Octokit::NotFound
      error_message = "File not found: #{@file_path} in repository #{@repo}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error retrieving file content: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end