class GithubAddPRLabelAction < Sublayer::Actions::Base
  def initialize(repo:, pr_number:, label:)
    @repo = repo
    @pr_number = pr_number
    @label = label
    @client = Octokit::Client.new(access_token: ENV["GITHUB_ACCESS_TOKEN"])
  end

  def call
    begin
      @client.add_labels_to_an_issue(@repo, @pr_number, [@label])
      Sublayer.configuration.logger.log(:info, "Label '#{@label}' successfully added to PR ##{@pr_number} in #{@repo}")
      true
    rescue Octokit::Error => e
      error_message = "Error adding label to PR: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      false
    end
  end
end
