require "sublayer/actions/base"
require "octokit"

module Sublayer
  module Actions
    class UpdateGithubPullRequestStatusAction < Sublayer::Actions::Base
      def initialize(repository:, pull_request_number:, status:)
        @repository = repository
        @pull_request_number = pull_request_number
        @status = status

        validate_input
      end

      def call
        client = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])

        case @status.downcase
        when "merge"
          client.pull_request.merge(
            @repository,
            @pull_request_number,
            merge_method: "squash"
          )
          logger.info "Merged pull request #{@pull_request_number} in #{@repository}"
        when "close"
          client.pull_request.update(
            @repository,
            @pull_request_number,
            state: "closed"
          )
          logger.info "Closed pull request #{@pull_request_number} in #{@repository}"
        else
          raise ArgumentError, "Invalid status: #{@status}. Allowed values are: 'merge', 'close'"
        end
      rescue Octokit::Error => e
        logger.error "Error updating pull request status: #{e.message}"
        raise
      end

      private

      def validate_input
        raise ArgumentError, "Repository cannot be blank" if @repository.blank?
        raise ArgumentError, "Pull request number cannot be blank" if @pull_request_number.blank?
        raise ArgumentError, "Status cannot be blank" if @status.blank?
      end
    end
  end
end