require 'dropbox_api'

# Description: Sublayer::Action responsible for downloading a file from a specified Dropbox link and storing it locally.
# This action allows easy integration for retrieving files from Dropbox into Sublayer workflows,
# enabling processing or usage of the file content by subsequent actions.
#
# It is initialized with a dropbox_link and a local_path where the file will be saved.
#
# Example usage: When you need to download a resource from Dropbox as part of an automated process to analyze or use in a further step.

class DropboxDownloadFileAction < Sublayer::Actions::Base
  def initialize(dropbox_link:, local_path:)
    @dropbox_link = dropbox_link
    @local_path = local_path
    @client = DropboxApi::Client.new(ENV['DROPBOX_ACCESS_TOKEN'])
  end

  def call
    begin
      download_file
      Sublayer.configuration.logger.log(:info, "File downloaded successfully from Dropbox: #{@dropbox_link}")
    rescue DropboxApi::Errors::HttpError => e
      error_message = "HTTP error during Dropbox file download: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error downloading file from Dropbox: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def download_file
    uri = URI.parse(@dropbox_link)
    path = uri.path
    file_metadata, file_content = @client.download(path)

    File.open(@local_path, 'wb') do |file|
      file.write(file_content)
    end
  end
end
