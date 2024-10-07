class GetPRFileInfoAction < Sublayer::Actions::Base
  def initialize(repo:, pr_number:)
    @repo = repo
    @pr_number = pr_number
    @client = Octokit::Client.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])
  end

  def call
    files = @client.pull_request_files(@repo, @pr_number)

    {
      file_name: files.first.filename,
      file_url: files.first.blob_url
    }
  end
end
