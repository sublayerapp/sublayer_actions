require 'gitlab'

# Description: Sublayer::Action responsible for creating a merge request in GitLab.
# This action automates the creation of merge requests, facilitating AI-suggested changes or code review workflows.
#
# It is initialized with project_id, source_branch, target_branch, title, and optional description.
# It returns the ID of the created merge request.
#
# Example usage: Use this action when AI suggests changes that need to be reviewed and merged in a GitLab project.

class GitLabCreateMergeRequestAction < Sublayer::Actions::Base
  def initialize(project_id:, source_branch:, target_branch:, title:, description: nil)
    @project_id = project_id
    @source_branch = source_branch
    @target_branch = target_branch
    @title = title
    @description = description
    @client = Gitlab.client(endpoint: ENV['GITLAB_API_ENDPOINT'], private_token: ENV['GITLAB_API_TOKEN'])
  end

  def call
    create_merge_request
  rescue Gitlab::Error::Error => e
    error_message = "Failed to create merge request: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def create_merge_request
    merge_request = @client.create_merge_request(
      @project_id,
      @title,
      {
        source_branch: @source_branch,
        target_branch: @target_branch,
        description: @description
      }
    )
    Sublayer.configuration.logger.log(:info, "Merge request created successfully in GitLab with ID: #{merge_request.id}")
    merge_request.id
  end
end
