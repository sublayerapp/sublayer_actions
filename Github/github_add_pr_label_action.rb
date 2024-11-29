class GithubAddPRLabelAction < GithubBase
  def initialize(repo:, pull_request_number:, label:)
    super(repo: repo)
    @pull_request_number = pull_request_number
    @label = label
  end

  def call
    begin
      @client.add_labels_to_an_issue(@repo, @pull_request_number, [@label])
      Sublayer.configuration.logger.log(:info, "Label '#{@label}' added to PR #{@pull_request_number} in repo #{@repo} successfully")
    rescue Octokit::Error => e
      Sublayer.configuration.logger.log(:error, "Error adding label to PR: #{e.message}")
      raise e
    end
  end
end