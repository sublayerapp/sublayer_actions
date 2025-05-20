require 'aws-sdk-s3'
require 'google/apis/drive_v3'
require 'googleauth'
require 'fileutils'
require 'zip'

# Description: Sublayer::Action responsible for creating compressed archives 
# of critical data directories and uploading them to cloud storage like AWS S3 or Google Drive.
#
# It can be used to automate the backup process of important directories ensuring data safety and accessibility.
#
# It is initialized with a directory_path, and cloud_service (either 'aws_s3' or 'google_drive'), and respective credentials.
# Example usage: When you want to back up logs, reports, or any important project data automatically to the cloud.

class DataBackupArchiverAction < Sublayer::Actions::Base
  def initialize(directory_path:, cloud_service:, aws_credentials: {}, google_credentials: {}, bucket_name: nil, drive_folder_id: nil)
    @directory_path = directory_path
    @cloud_service = cloud_service
    @aws_credentials = aws_credentials
    @google_credentials = google_credentials
    @bucket_name = bucket_name
    @drive_folder_id = drive_folder_id
    @archive_file = "#{File.basename(directory_path)}_backup.zip"
  end

  def call
    begin
      create_archive
      upload_archive
    rescue StandardError => e
      error_message = "Error during backup process: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      cleanup
    end
  end

  private

  def create_archive
    ::Zip::File.open(@archive_file, Zip::File::CREATE) do |zipfile|
      Dir[File.join(@directory_path, '**', '**')].each do |file|
        zipfile.add(file.sub(@directory_path + '/', ''), file)
      end
    end
    Sublayer.configuration.logger.log(:info, "Archive created: #{@archive_file}")
  end

  def upload_archive
    case @cloud_service
    when 'aws_s3'
      upload_to_aws_s3
    when 'google_drive'
      upload_to_google_drive
    else
      raise "Unsupported cloud service: #{@cloud_service}"
    end
  end

  def upload_to_aws_s3
    s3_client = Aws::S3::Client.new(@aws_credentials)
    s3_client.put_object(bucket: @bucket_name, key: @archive_file, body: File.read(@archive_file))
    Sublayer.configuration.logger.log(:info, "Archive uploaded to AWS S3: #{@archive_file}")
  end

  def upload_to_google_drive
    service = Google::Apis::DriveV3::DriveService.new
    service.client_options.application_name = 'Data Backup Archiver'
    service.authorization = @google_credentials

    file_metadata = {
      name: @archive_file,
      parents: [@drive_folder_id]
    }
    file = Google::Apis::DriveV3::File.new(file_metadata)
    service.create_file(file, upload_source: @archive_file, content_type: 'application/zip')
    Sublayer.configuration.logger.log(:info, "Archive uploaded to Google Drive: #{@archive_file}")
  end

  def cleanup
    File.delete(@archive_file) if File.exist?(@archive_file)
    Sublayer.configuration.logger.log(:info, "Cleanup complete for #{@archive_file}")
  end
end