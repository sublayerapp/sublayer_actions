require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'dropbox_api'

# Description: Sublayer::Action responsible for uploading files to a specified cloud storage service like Google Drive or Dropbox.
# This action uploads a file and returns the link to the uploaded file.
#
# It is initialized with a service (google_drive or dropbox), file_path to upload, and optional parameters for authentication and configuration.
# It returns the link to the uploaded file.
#
# Example usage: When you want to upload a report or result from an AI process to cloud storage for sharing or backup.

class CloudStorageFileUploaderAction < Sublayer::Actions::Base
  def initialize(service:, file_path:, credentials:, token_store: nil, folder_id: nil)
    @service = service
    @file_path = file_path
    @credentials = credentials
    @token_store = token_store
    @folder_id = folder_id
    setup_client
  end

  def call
    begin
      upload_file
    rescue StandardError => e
      error_message = "Error uploading file: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_client
    case @service
    when 'google_drive'
      @client = setup_google_drive_client
    when 'dropbox'
      @client = setup_dropbox_client
    else
      raise ArgumentError, "Unsupported cloud service: \#{@service}"
    end
  end

  def setup_google_drive_client
    scope = Google::Apis::DriveV3::AUTH_DRIVE_FILE
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: StringIO.new(@credentials), scope: scope)
    Google::Apis::DriveV3::DriveService.new.tap do |drive_service|
      drive_service.authorization = authorizer
    end
  end

  def setup_dropbox_client
    DropboxApi::Client.new(@credentials)
  end

  def upload_file
    case @service
    when 'google_drive'
      upload_to_google_drive
    when 'dropbox'
      upload_to_dropbox
    else
      raise ArgumentError, "Unsupported cloud service: \#{@service}"
    end
  end

  def upload_to_google_drive
    file_metadata = { name: File.basename(@file_path), parents: [@folder_id].compact }
    file = @client.create_file(file_metadata, upload_source: @file_path, content_type: mime_type(@file_path))
    "https://drive.google.com/file/d/\#{file.id}/view"
  end

  def upload_to_dropbox
    file_content = File.read(@file_path)
    file = @client.upload(File.basename(@file_path), file_content)
    @client.create_shared_link_with_settings(file.path_lower).url
  end

  def mime_type(file_path)
    `file --brief --mime-type \#{file_path}`.strip
  end
end