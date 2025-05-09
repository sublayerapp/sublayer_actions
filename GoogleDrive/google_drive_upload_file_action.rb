require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Description: Sublayer::Action responsible for uploading a file to a specified directory in Google Drive.
# This action allows AI-generated files to be stored in a centralized, accessible online location.
#
# It is initialized with a file_path, drive_folder_id, and optionally a file_name.
# It returns the file ID of the uploaded file in Google Drive.
#
# Example usage: When you want to store LLM-generated reports or data files in Google Drive for easy sharing and access.

class GoogleDriveUploadFileAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Drive API Ruby Quickstart'
  CREDENTIALS_PATH = 'path/to/credentials.json'
  TOKEN_PATH = 'path/to/token.yaml'
  SCOPE = Google::Apis::DriveV3::AUTH_DRIVE_FILE

  def initialize(file_path:, drive_folder_id:, file_name: nil)
    @file_path = file_path
    @drive_folder_id = drive_folder_id
    @file_name = file_name || File.basename(file_path)
    @service = setup_service
  end

  def call
    begin
      file_metadata = {
        name: @file_name,
        parents: [@drive_folder_id]
      }
      file = @service.create_file(
        file_metadata,
        fields: 'id',
        upload_source: @file_path,
        content_type: 'application/octet-stream'
      )
      Sublayer.configuration.logger.log(:info, "File uploaded successfully. File ID: #{file.id}")
      file.id
    rescue Google::Apis::Error => e
      error_message = "Failed to upload file to Google Drive: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_service
    client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the resulting code after authorization: \n \#{url}"
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    service = Google::Apis::DriveV3::DriveService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = credentials
    service
  end
end
