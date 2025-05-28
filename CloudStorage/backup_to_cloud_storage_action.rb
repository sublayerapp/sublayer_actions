require 'aws-sdk-s3'
require 'google/apis/drive_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for backing up specified files or directories to a cloud storage provider like AWS S3 or Google Drive.
# This action ensures data safety and accessibility by uploading specified files to the cloud.
#
# It is initialized with the cloud provider, credentials, and a list of files or directories to backup.
# It utilizes provider-specific gems for AWS and Google Drive for file uploads.
#
# Example usage: Use this action to backup important files to the cloud as part of an AI-driven workflow or data management strategy.

class BackupToCloudStorageAction < Sublayer::Actions::Base
  def initialize(provider:, credentials:, backup_items: [])
    @provider = provider
    @credentials = credentials
    @backup_items = backup_items
    @client = initialize_client
  end

  def call
    perform_backup
  rescue StandardError => e
    error_message = "Error backing up data to cloud storage: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def initialize_client
    case @provider.downcase
    when 'aws_s3'
      Aws::S3::Client.new(@credentials)
    when 'google_drive'
      service = Google::Apis::DriveV3::DriveService.new
      service.authorization = Google::Auth.get_application_default([Google::Apis::DriveV3::AUTH_DRIVE])
      service
    else
      raise StandardError, "Unsupported cloud provider: #{@provider}"
    end
  end

  def perform_backup
    @backup_items.each do |item|
      if File.directory?(item)
        zip_and_upload_directory(item)
      elsif File.file?(item)
        upload_file(item)
      else
        raise StandardError, "Invalid item type for backup: #{item}"
      end
    end
  end

  def zip_and_upload_directory(directory)
    zipfile_name = "#{directory}.zip"
    system("zip -r #{zipfile_name} #{directory}")
    upload_file(zipfile_name)
    File.delete(zipfile_name) if File.exist?(zipfile_name)
  end

  def upload_file(file_path)
    case @provider.downcase
    when 'aws_s3'
      bucket = @credentials[:bucket]
      object_key = File.basename(file_path)
      @client.put_object(bucket: bucket, key: object_key, body: File.open(file_path, 'rb'))
      Sublayer.configuration.logger.log(:info, "File uploaded successfully to AWS S3: #{object_key}")
    when 'google_drive'
      file_metadata = { name: File.basename(file_path) }
      file = Google::Apis::DriveV3::File.new(name: file_metadata[:name])
      @client.create_file(file, upload_source: file_path, content_type: 'application/zip')
      Sublayer.configuration.logger.log(:info, "File uploaded successfully to Google Drive: #{file_metadata[:name]}")
    else
      raise StandardError, "Unsupported cloud provider for file upload: #{@provider}"
    end
  end
end
