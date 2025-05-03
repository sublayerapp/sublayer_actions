# Description: Sublayer::Action responsible for backing up specified files or data to a cloud service 
# such as AWS S3 or Google Drive for secure storage and easy access from anywhere.
#
# This action allows users to specify the files to be backed up and choose a cloud service for storage.
# It ensures data safety and accessibility from any location where the cloud service is accessible.
#
# Example usage: When you want to back up important data files regularly to prevent data loss.

require 'aws-sdk-s3'
require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

class DataBackupToCloudAction < Sublayer::Actions::Base
  def initialize(files:, provider:, aws_credentials: {}, google_credentials: {}, folder_id: nil)
    @files = files
    @provider = provider.downcase
    @aws_credentials = aws_credentials
    @google_credentials = google_credentials
    @folder_id = folder_id
  end

  def call
    case @provider
    when 'aws'
      backup_to_aws_s3
    when 'google'
      backup_to_google_drive
    else
      error_message = "Unsupported cloud provider: #{@provider}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def backup_to_aws_s3
    begin
      s3_client = Aws::S3::Client.new(@aws_credentials)

      @files.each do |file_path|
        file_name = File.basename(file_path)
        s3_client.put_object(bucket: ENV['AWS_S3_BUCKET'], key: file_name, body: File.read(file_path))
        Sublayer.configuration.logger.log(:info, "Successfully backed up #{file_name} to AWS S3")
      end
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error backing up files to AWS S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def backup_to_google_drive
    begin
      service = Google::Apis::DriveV3::DriveService.new
      service.client_options.application_name = 'SublayerBackup'
      service.authorization = authorize_google

      @files.each do |file_path|
        file_metadata = {
          name: File.basename(file_path),
          parents: [@folder_id]
        }
        file = Google::Apis::DriveV3::File.new(file_metadata)
        service.create_file(file, upload_source: file_path, content_type: 'application/octet-stream')
        Sublayer.configuration.logger.log(:info, "Successfully backed up #{File.basename(file_path)} to Google Drive")
      end
    rescue Google::Apis::Error => e
      error_message = "Error backing up files to Google Drive: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def authorize_google
    client_id = Google::Auth::ClientId.from_file(@google_credentials[:client_secrets_file])
    token_store = Google::Auth::Stores::FileTokenStore.new(file: @google_credentials[:token_store_file])
    authorizer = Google::Auth::UserAuthorizer.new(client_id, Google::Apis::DriveV3::AUTH_DRIVE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: 'urn:ietf:wg:oauth:2.0:oob')
      puts "Open the following URL in the browser and enter the resulting code after authorization:
#{url}"
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: 'urn:ietf:wg:oauth:2.0:oob')
    end
    credentials
  end
end
