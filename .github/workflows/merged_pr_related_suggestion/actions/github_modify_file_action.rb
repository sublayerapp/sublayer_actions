class GithubModifyFileAction < GithubBase
  def initialize(repo:, branch:, file_path:, file_content:)
    super(repo: repo)
    @branch = branch
    @file_path = file_path
    @file_content = file_content
  end

  def call
    content = @client.contents(@repo, path: @file_path, ref: @branch)
    @client.update_contents(
      @repo,
      @file_path,
      "Updating #{@file_path}",
      content.sha,
      @file_content,
      branch: @branch
    )
  end
end
