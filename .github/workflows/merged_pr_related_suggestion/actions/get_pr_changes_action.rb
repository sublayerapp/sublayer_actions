class GetPRChangesAction < Sublayer::Actions::Base
  def initialize(repo:, pr_number:)
    @repo = repo
    @pr_number = pr_number
    @client = Octokit::Client.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])
  end

  def call
    pr = @client.pull_request(@repo, @pr_number)
    files = @client.pull_request_files(@repo, @pr_number)

    {
      title: pr.title,
      body: pr.body,
      changed_files: files.map do |file|
        {
          filename: file.filename,
          patch: file.patch
        }
      end
    }
  end
end
