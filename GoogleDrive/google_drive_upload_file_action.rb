require 'google/apis/drive_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for uploading files to Google Drive.
# This action allows for programmatic file uploads with folder organization and sharing settings,
# making it useful for AI workflows that generate files that need to be stored and shared.
#
# Requires: 'google-api-client' and 'googleauth' gems
# $ gem install google-api-client googleauth
# Or add to your Gemfile:
# gem 'google-api-client'
# gem 'googleauth'
#
# Authentication:
# Requires a Google Cloud service account credentials JSON file path in GOOGLE_DRIVE_CREDENTIALS env var
#
# It is initialized with:
# - file_path: Local path to the file to upload
# - folder_id: (Optional) Google Drive folder ID to upload to
# - mime_type: MIME type of the file
# - title: (Optional) Custom title for the file in Drive (defaults to original filename)
# - share_with: (Optional) Email addresses to share the file with
# - share_role: (Optional) Role for sharing ('reader', 'writer', or 'commenter')
#
# Returns: The Google Drive file ID of the uploaded file
#
# Example usage: When an AI generates a document or image that needs to be stored
# and potentially shared with specific users via Google Drive.

class GoogleDriveUploadFileAction < Sublayer::Actions::Base
  def initialize(file_path:, folder_id: nil, mime_type:, title: nil, share_with: nil, share_role: 'reader')
    @file_path = file_path
    @folder_id = folder_id
    @mime_type = mime_type
    @title = title || File.basename(@file_path)
    @share_with = share_with
    @share_role = share_role
    @service = initialize_service
  end

  def call
    begin
      file_id = upload_file
      share_file(file_id) if @share_with
      
      Sublayer.configuration.logger.log(:info, "Successfully uploaded file to Google Drive with ID: #{file_id}")
      file_id
    rescue Google::Apis::Error => e
      error_message = "Google Drive API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error uploading file to Google Drive: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def initialize_service
    service = Google::Apis::DriveV3::DriveService.new
    credentials = Google::Auth::ServiceAccountCredentials.from_env(
      'GOOGLE_DRIVE_CREDENTIALS'
    )
    credentials.scope = ['https://www.googleapis.com/auth/drive']
    service.authorization = credentials
    service
  end

  def upload_file
    file_metadata = {
      name: @title
    }

    # Add to specific folder if folder_id is provided
    file_metadata[:parents] = [@folder_id] if @folder_id

    file = @service.create_file(
      file_metadata,
      fields: 'id',
      upload_source: @file_path,
      content_type: @mime_type
    )

    file.id
  end

  def share_file(file_id)
    return unless @share_with

    emails = @share_with.is_a?(Array) ? @share_with : [@share_with]
    
    emails.each do |email|
      permission = {
        type: 'user',
        role: @share_role,
        email_address: email
      }

      @service.create_permission(
        file_id,
        permission,
        fields: 'id'
      )

      Sublayer.configuration.logger.log(:info, "Shared file #{file_id} with #{email}")
    end
  end
end