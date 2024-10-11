# Description: Sublayer::Action that automates the process of publishing a release on GitHub,
# facilitating version management and software deployment.
#
# It is initialized with a repository, tag name, release name, and optional description and files to upload.
# It returns the created release URL as confirmation of success.
#
# Example usage: When automating deployment workflows and need to publish a release to notify users of new software versions.

class GithubReleasePublisherAction < GithubBase
  def initialize(repo:, tag_name:, release_name:, description: nil, files: [], **kwargs)
    super(repo: repo)
    @tag_name = tag_name
    @release_name = release_name
    @description = description
    @files = files
  end

  def call
    begin
      release = @client.create_release(
        @repo,
        @tag_name,
        name: @release_name,
        body: @description,
        draft: false,
        prerelease: false
      )

      upload_assets(release) unless @files.empty?
      Sublayer.configuration.logger.log(:info, "Release '#{@release_name}' published successfully")
      release.url
    rescue StandardError => e
      error_message = "Error publishing release: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def upload_assets(release)
    @files.each do |file|
      begin
        @client.upload_asset(
          release.rels[:upload].href,
          file,
          content_type: `file --brief --mime-type #{file}`.strip
        )
      rescue StandardError => e
        Sublayer.configuration.logger.log(:error, "Error uploading asset '#{file}': #{e.message}")
        # Continue with other files even if one fails
      end
    end
  end
end
