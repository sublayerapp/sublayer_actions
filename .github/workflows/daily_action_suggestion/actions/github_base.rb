class GithubBase < Sublayer::Actions::Base
  def initialize(repo:)
    @repo = repo
    @client = Octokit::Client.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])
  end
end
