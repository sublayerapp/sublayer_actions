require 'octokit'

# Description: Sublayer::Action to add or update a comment on a GitHub issue or pull request.
#
# It is initialized with the repository name, issue/PR number, and the comment body.
# It either creates a new comment or updates the existing comment if one created by the same actor already exists on the issue/pr
#
# Example usage: An AI agent automatically responding to or providing updates on issues.

class GithubAddOrUpdateCommentAction < Sublayer::Actions::Base
  def initialize(repo:, issue_number:, comment_body:)
    @repo = repo
    @issue_number = issue_number
    @comment_body = comment_body
    @client = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
    @user = @client.user.login
  end

  def call
    begin
      existing_comment = find_existing_comment
      if existing_comment
        update_comment(existing_comment.id)
      else
        create_comment
      end
    rescue Octokit::NotFound => e
      error_message = "Issue or pull request not found: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error adding/updating comment: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def find_existing_comment
    comments = @client.issue_comments(@repo, @issue_number)
    comments.find { |comment| comment.user.login == @user }
  end

  def create_comment
    @client.add_comment(@repo, @issue_number, @comment_body)
    Sublayer.configuration.logger.log(:info, "Comment created successfully on issue \##{@issue_number} in #{@repo}")
  end

  def update_comment(comment_id)
    @client.update_comment(@repo, comment_id, @comment_body)
    Sublayer.configuration.logger.log(:info, "Comment updated successfully on issue \##{@issue_number} in #{@repo}")
  end
end