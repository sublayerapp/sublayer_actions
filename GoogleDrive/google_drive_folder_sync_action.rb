require 'google/apis/drive_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for synchronizing a local folder with Google Drive.
# This action handles file uploads, updates, and deletions to keep a local folder in sync with Google Drive.
#
# Requires: 'google-api-client' and 'googleauth' gems
# $ gem install google-api-client googleauth
# Or add to your Gemfile:
# gem 'google-api-client'
# gem 'googleauth'
#
# It is initialized with a local folder path and Google Drive folder ID.
# Returns a hash containing counts of files uploaded, updated, and deleted.
#
# Example usage: When you have an AI system generating files that need to be automatically
# backed up or shared via Google Drive.

class GoogleDriveFolderSyncAction < Sublayer::Actions::Base
  def initialize(local_folder_path:, drive_folder_id:)
    @local_folder_path = local_folder_path
    @drive_folder_id = drive_folder_id
    @service = initialize_drive_service
  end

  def call
    begin
      sync_stats = sync_folder
      Sublayer.configuration.logger.log(:info, "Folder sync completed: #{sync_stats}")
      sync_stats
    rescue Google::Apis::Error => e
      error_message = "Google Drive API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error syncing folder: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def initialize_drive_service
    service = Google::Apis::DriveV3::DriveService.new
    service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(ENV['GOOGLE_DRIVE_CREDENTIALS']),
      scope: Google::Apis::DriveV3::AUTH_DRIVE_FILE
    )
    service
  end

  def sync_folder
    stats = { uploads: 0, updates: 0, deletions: 0 }

    # Get existing files in Drive folder
    drive_files = list_drive_files
    drive_file_map = drive_files.each_with_object({}) { |file, map| map[file.name] = file }

    # Get local files
    local_files = Dir.glob(File.join(@local_folder_path, '**/*')).reject { |f| File.directory?(f) }
    local_file_names = local_files.map { |f| File.basename(f) }.to_set

    # Handle updates and uploads
    local_files.each do |local_path|
      file_name = File.basename(local_path)
      if drive_file_map[file_name]
        update_file(local_path, drive_file_map[file_name].id)
        stats[:updates] += 1
      else
        upload_file(local_path)
        stats[:uploads] += 1
      end
    end

    # Handle deletions
    drive_files.each do |file|
      unless local_file_names.include?(file.name)
        delete_file(file.id)
        stats[:deletions] += 1
      end
    end

    stats
  end

  def list_drive_files
    @service.list_files(
      q: "'#{@drive_folder_id}' in parents and trashed = false",
      fields: 'files(id, name)'
    ).files
  end

  def upload_file(local_path)
    file_metadata = {
      name: File.basename(local_path),
      parents: [@drive_folder_id]
    }

    @service.create_file(
      file_metadata,
      fields: 'id',
      upload_source: local_path,
      content_type: content_type(local_path)
    )
  end

  def update_file(local_path, file_id)
    @service.update_file(
      file_id,
      fields: 'id',
      upload_source: local_path,
      content_type: content_type(local_path)
    )
  end

  def delete_file(file_id)
    @service.delete_file(file_id)
  end

  def content_type(file_path)
    case File.extname(file_path).downcase
    when '.txt'
      'text/plain'
    when '.pdf'
      'application/pdf'
    when '.json'
      'application/json'
    when '.jpg', '.jpeg'
      'image/jpeg'
    when '.png'
      'image/png'
    else
      'application/octet-stream'
    end
  end
end