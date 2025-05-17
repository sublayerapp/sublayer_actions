require 'gitlab'

# Description: Sublayer::Action responsible for creating an issue in GitLab projects.
# This action integrates with GitLab using the GitLab Ruby client,
# streamlining the creation of issues based on AI-generated insights like bug identification or feature requests.
#
# It is initialized with project_id, title, and optional description, labels, and milestone_id.
# It returns the ID of the created issue.
#
# Example usage: Use it to automate the creation of GitLab issues from AI-identified bugs or requested features.

class GitlabIssueCreationAction < Sublayer::Actions::Base
  def initialize(project_id:, title:, description: '', labels: [], milestone_id: nil)
    @project_id = project_id
    @title = title
    @description = description
    @labels = labels
    @milestone_id = milestone_id
    @client = Gitlab.client(endpoint: ENV['GITLAB_API_ENDPOINT'], private_token: ENV['GITLAB_PRIVATE_TOKEN'])
  end

  def call
    create_issue
  rescue Gitlab::Error::Error => e
    error_message = "Error creating GitLab issue: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def create_issue
    issue = @client.create_issue(
      @project_id,
      @title,
      description: @description,
      labels: @labels.join(','),
      milestone_id: @milestone_id
    )

    if issue
      Sublayer.configuration.logger.log(:info, "Issue created successfully in GitLab with ID: #{issue.id}")
      issue.id
    else
      error_message = "Failed to create issue in GitLab."
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
