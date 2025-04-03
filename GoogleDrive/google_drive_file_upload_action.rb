require 'google/apis/drive_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for uploading a file to a specified Google Drive folder.
# This action enables integration with Google Drive for cloud storage capabilities.
#
# It is initialized with a file_path and a drive_folder_id where you want to upload the file.
# It returns the ID of the uploaded file on success.
#
# Example usage: When you want to upload LLM-generated content or workflow files to Google Drive for persistent storage.

class GoogleDriveFileUploadAction < Sublayer::Actions::Base
  DRIVE_SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_FILE

  def initialize(file_path:, drive_folder_id:)
    @file_path = file_path
    @drive_folder_id = drive_folder_id
    @drive_service = Google::Apis::DriveV3::DriveService.new
    @drive_service.authorization = Google::Auth.get_application_default([DRIVE_SCOPE])
  end

  def call
    begin
      upload_file
    rescue Google::Apis::Error => e
      error_message = "Error uploading file to Google Drive: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    file_metadata = {
      name: File.basename(@file_path),
      parents: [@drive_folder_id]
    }
    file = File.open(@file_path, 'rb')
    begin
      response = @drive_service.create_file(file_metadata,
                                            fields: 'id',
                                            upload_source: file,
                                            content_type: 'application/octet-stream')
      Sublayer.configuration.logger.log(:info, "File uploaded successfully to Google Drive with ID: #{response.id}")
      response.id
    ensure
      file.close
    end
  end
end