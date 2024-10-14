require 'aws-sdk-s3'
require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'
require 'tempfile'

# Description: Sublayer::Action responsible for backing up specified files or databases to a cloud storage provider like AWS S3 or Google Drive.
# This action helps in maintaining data integrity and safety by creating backups regularly.
#
# It is initialized with a list of files to backup and the desired cloud storage provider.
# Example usage: When you need to backup important files or database dumps to AWS S3 or Google Drive for safekeeping.

class DataBackupAction < Sublayer::Actions::Base
  def initialize(files:, provider: :aws, bucket_name: nil, folder_id: nil)
    @files = files
    @provider = provider
    @bucket_name = bucket_name
    @folder_id = folder_id
  end

  def call
    case @provider
    when :aws
      backup_to_aws_s3
    when :google_drive
      backup_to_google_drive
    else
      raise ArgumentError, "Unsupported provider: #{@provider}"
    end
  end

  private

  def backup_to_aws_s3
    s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'])
    @files.each do |file|
      begin
        file_name = File.basename(file)
        Sublayer.configuration.logger.log(:info, "Backing up #{file} to AWS S3 bucket: #{@bucket_name}")
        s3_client.put_object(bucket: @bucket_name, key: file_name, body: File.read(file))
      rescue Aws::S3::Errors::ServiceError => e
        Sublayer.configuration.logger.log(:error, "Error backing up #{file} to AWS S3: #{e.message}")
        raise e
      end
    end
  end

  def backup_to_google_drive
    credentials_path = 'path/to/credentials.json'
    token_path = 'path/to/token.yaml'
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: Google::Apis::DriveV3::AUTH_DRIVE_FILE
    )
    drive_service = Google::Apis::DriveV3::DriveService.new
    drive_service.authorization = authorizer

    @files.each do |file|
      begin
        file_metadata = Google::Apis::DriveV3::File.new(name: File.basename(file), parents: [@folder_id])
        drive_service.create_file(file_metadata, upload_source: file, content_type: 'application/octet-stream')
        Sublayer.configuration.logger.log(:info, "Succesfully backed up #{file} to Google Drive folder: #{@folder_id}")
      rescue Google::Apis::ClientError => e
        Sublayer.configuration.logger.log(:error, "Error backing up #{file} to Google Drive: #{e.message}")
        raise e
      end
    end
  end
end
