require 'aws-sdk-s3'
require 'google/cloud/storage'
require 'azure/storage/blob'

# Description: Sublayer::Action responsible for uploading files to cloud storage platforms such as AWS S3, Google Cloud Storage, and Azure Blob Storage.
# This is useful for persisting AI-generated outputs in a reliable cloud-based storage solution.
#
# Initialization options:
# - service: The cloud storage service provider (:aws_s3, :google_cloud_storage, :azure_blob)
# - bucket: The name of the cloud storage bucket/container
# - file_path: The local path to the file to be uploaded
# - remote_path: The path in the cloud storage where the file will be stored
#
# Example usage: When you want to store AI-generated files in a cloud service for later retrieval or processing.

class CloudStorageUploadAction < Sublayer::Actions::Base
  def initialize(service:, bucket:, file_path:, remote_path:)
    @service = service
    @bucket = bucket
    @file_path = file_path
    @remote_path = remote_path
    configure_client
  end

  def call
    case @service
    when :aws_s3
      upload_to_aws_s3
    when :google_cloud_storage
      upload_to_google_cloud_storage
    when :azure_blob
      upload_to_azure_blob
    else
      error_message = "Unsupported cloud service: #{@service}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise ArgumentError, error_message
    end
  rescue StandardError => e
    error_message = "Error uploading file to cloud storage: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def configure_client
    case @service
    when :aws_s3
      @client = Aws::S3::Client.new(region: ENV['AWS_REGION'], access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
    when :google_cloud_storage
      @client = Google::Cloud::Storage.new(project_id: ENV['GOOGLE_CLOUD_PROJECT_ID'], credentials: ENV['GOOGLE_CLOUD_CREDENTIALS'])
    when :azure_blob
      @client = Azure::Storage::Blob::BlobService.create(storage_account_name: ENV['AZURE_STORAGE_ACCOUNT_NAME'], storage_access_key: ENV['AZURE_STORAGE_ACCESS_KEY'])
    end
  end

  def upload_to_aws_s3
    File.open(@file_path, 'rb') do |file|
      @client.put_object(bucket: @bucket, key: @remote_path, body: file)
    end
    Sublayer.configuration.logger.log(:info, "File successfully uploaded to AWS S3: #{@remote_path}")
  end

  def upload_to_google_cloud_storage
    bucket = @client.bucket(@bucket)
    bucket.create_file(@file_path, @remote_path)
    Sublayer.configuration.logger.log(:info, "File successfully uploaded to Google Cloud Storage: #{@remote_path}")
  end

  def upload_to_azure_blob
    content = File.open(@file_path, 'rb', &:read)
    @client.create_block_blob(@bucket, @remote_path, content)
    Sublayer.configuration.logger.log(:info, "File successfully uploaded to Azure Blob Storage: #{@remote_path}")
  end
end
