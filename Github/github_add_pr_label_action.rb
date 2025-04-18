require 'octokit'

# Description: Sublayer::Action responsible for adding a specified label to a GitHub pull request.
# This action allows for easy labeling of pull requests, which can be useful for categorization,
# automated workflows, or indicating the status/type of a PR.
#
# It inherits from GithubBase to handle authentication and client setup.
#
# It is initialized with a repo, pr_number, and label.
# It returns true if the label was successfully added, false otherwise.
#
# Example usage: When you want to automatically label pull requests based on certain criteria
# or as part of an AI-driven workflow.

class GithubAddPRLabelAction < GithubBase
  def initialize(repo:, pr_number:, label:)
    super(repo: repo)
    @pr_number = pr_number
    @label = label
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
