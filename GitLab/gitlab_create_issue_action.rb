require 'gitlab'

# Description: Sublayer::Action responsible for creating a new issue in a specified GitLab project.
# This action allows integration with GitLab for automation of issue creation based on AI-driven insights or processes.
#
# Requires: `gitlab` gem
# $ gem install gitlab
# Or add `gem 'gitlab'` to your Gemfile
#
# It is initialized with project_id, title, and optional description and labels.
# It returns the issue ID of the created GitLab issue.
#
# Example usage: When you want to create a GitLab issue based on insights generated from AI models.

class GitLabCreateIssueAction < Sublayer::Actions::Base
  def initialize(project_id:, title:, description: nil, labels: [])
    @project_id = project_id
    @title = title
    @description = description
    @labels = labels
    @client = Gitlab.client(endpoint: ENV['GITLAB_API_ENDPOINT'], private_token: ENV['GITLAB_API_PRIVATE_TOKEN'])
  end

  def call
    begin
      issue = create_issue
      Sublayer.configuration.logger.log(:info, "GitLab issue created successfully: \\#{issue.iid}")
      issue.iid
    rescue Gitlab::Error::Error => e
      error_message = "Error creating GitLab issue: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_issue
    @client.create_issue(@project_id, @title, description: @description, labels: @labels.join(','))
  end
end
