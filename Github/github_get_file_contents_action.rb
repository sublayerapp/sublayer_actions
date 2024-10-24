# Description: Sublayer::Action responsible for retrieving the contents of a specified file from a GitHub repository.
# This action allows easy access to file contents for processing or analysis within a Sublayer workflow.
#
# It is initialized with a repo, branch, and file_path.
# It returns the content of the specified file.
#
# Example usage: When you want to read the content of a configuration file in a GitHub repository
# for use in an AI-driven process or analysis.

class GithubGetFileContentsAction < GithubBase
  def initialize(repo:, branch:, file_path:)
    super(repo: repo)
    @branch = branch
    @file_path = file_path
  end

  def call
    begin
      content = get_file_contents
      Sublayer.configuration.logger.log(:info, "Successfully retrieved contents for file \\"#{@file_path}\\" in repo \\"#{@repo}\\" on branch \\"#{@branch}\\"")
      content
    rescue Octokit::NotFound => e
      error_message = "Error fetching file contents: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error retrieving file contents: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def get_file_contents
    response = @client.contents(@repo, path: @file_path, ref: @branch)
    Base64.decode64(response.content)
  end
end
