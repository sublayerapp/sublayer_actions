# Description: Sublayer::Action responsible for retrieving the contents of a specific file from a GitHub repository.
# This action allows for easy integration with GitHub, enabling retrieval of file contents for further processing or analysis.
#
# It is initialized with the repository name, file path, and an optional branch name.
# It returns the contents of the specified file as a string.
#
# Example usage: When you need to fetch the contents of a specific file from a GitHub repository for analysis or processing in an AI workflow.

class GithubGetFileContentsAction < GithubBase
  def initialize(repo:, file_path:, branch: 'main')
    super(repo: repo)
    @file_path = file_path
    @branch = branch
  end

  def call
    begin
      content = @client.contents(@repo, path: @file_path, ref: @branch)
      decoded_content = Base64.decode64(content.content)
      Sublayer.configuration.logger.log(:info, "Successfully retrieved contents of #{@file_path} from #{@repo}")
      decoded_content
    rescue Octokit::Error => e
      error_message = "Error fetching file contents: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end