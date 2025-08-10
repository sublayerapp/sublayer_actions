require 'google/apis/drive_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for downloading a file from Google Drive using a file ID.
# This action allows for integration with Google Drive, enabling workflows that involve the usage or analysis of cloud-stored files.
#
# Requires: 'google-api-client' gem
# $ gem install google-api-client
#
# It is initialized with a file_id and an optional download_path.
# It saves the file to the specified path or returns its content.
#
# Example usage: When you need to download a file from Google Drive for processing or analysis in your AI-driven workflow.

class GoogleDriveFileDownloadAction < Sublayer::Actions::Base
  Drive = Google::Apis::DriveV3 # Alias the module to simplify code
  
  def initialize(file_id:, download_path: nil)
    # Setup authentication and Drive service
    @file_id = file_id
    @download_path = download_path
    @service = Drive::DriveService.new
    @service.client_options.application_name = 'Sublayer'
    @service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/drive.readonly'])
  end

  def call
    download_file
  rescue Google::Apis::ServerError => e
    log_error("Server error during file download: #{e.message}", e)
  rescue Google::Apis::ClientError => e
    log_error("Client error during file download (check file ID and permissions): #{e.message}", e)
  rescue Google::Apis::AuthorizationError => e
    log_error("Authorization error: #{e.message}", e)
  rescue StandardError => e
    log_error("Unexpected error during file download: #{e.message}", e)
  end

  private

  def download_file
    if @download_path
      File.open(@download_path, 'wb') do |file|
        @service.get_file(@file_id, download_dest: file)
      end
      Sublayer.configuration.logger.log(:info, "File downloaded successfully to #{@download_path}")
    else
      StringIO.new.tap do |string_io|
        @service.get_file(@file_id, download_dest: string_io)
      end.string
    end
  end

  def log_error(message, exception)
    Sublayer.configuration.logger.log(:error, message)
    raise StandardError, message
  end
end