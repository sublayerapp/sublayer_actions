require 'gitlab'

# Description: Sublayer::Action responsible for creating a merge request in GitLab.
# This action helps automate the creation of merge requests, facilitating integration and release management in code repositories.
#
# It is initialized with the project_id, source_branch, target_branch, title, and optional description.
# It returns the IID of the created merge request.
#
# Example usage: When you want to automate the creation of a merge request after pushing changes to a branch.

class GitLabCreateMergeRequestAction < Sublayer::Actions::Base
  def initialize(project_id:, source_branch:, target_branch:, title:, description: nil)
    @project_id = project_id
    @source_branch = source_branch
    @target_branch = target_branch
    @title = title
    @description = description
    @client = Gitlab.client(endpoint: ENV['GITLAB_API_ENDPOINT'], private_token: ENV['GITLAB_API_PRIVATE_TOKEN'])
  end

  def call
    begin
      merge_request = @client.create_merge_request(
        @project_id,
        @title,
        source_branch: @source_branch,
        target_branch: @target_branch,
        description: @description
      )
      Sublayer.configuration.logger.log(:info, "Merge request created successfully in GitLab with IID: #{merge_request.iid}")
      merge_request.iid
    rescue Gitlab::Error => e
      error_message = "Error creating GitLab merge request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end