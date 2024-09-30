class GithubCreateFileAction < GithubBase
  def initialize(repo:, branch:, file_path:, file_content:)
    super(repo: repo)
    @branch = branch
    @file_path = file_path
    @file_content = file_content
  end

  def call
    @client.create_contents(
      @repo,
      @file_path,
      "Creating #{@file_path}",
      @file_content,
      branch: @branch
    )
  end
end
