require 'aws-sdk-s3'
require 'google/cloud/storage'
require 'azure/storage/blob'

# Description: Sublayer::Action responsible for backing up datasets to specified cloud storage providers
# like AWS S3, Google Cloud Storage, and Azure Blobs. This action supports secure data management and 
# safeguarding by ensuring data is stored in multiple locations.
#
# It is initialized with parameters specific to cloud providers and dataset details.
# It returns a confirmation message on successful backup.
#
# Example usage: Use this action to backup sensitive datasets following data processing or at scheduled intervals.

class DataBackupToCloudAction < Sublayer::Actions::Base
  def initialize(provider:, dataset_path:, backup_location:, access_credentials: {})
    @provider = provider.downcase
    @dataset_path = dataset_path
    @backup_location = backup_location
    @access_credentials = access_credentials
  end

  def call
    case @provider
    when 'aws'
      backup_to_aws
    when 'google'
      backup_to_google
    when 'azure'
      backup_to_azure
    else
      error_message = "Unsupported provider: #{@provider}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error during backup: #{e.message}")
    raise e
  end

  private

  def backup_to_aws
    client = Aws::S3::Client.new(
      region: @access_credentials[:region],
      access_key_id: @access_credentials[:access_key_id],
      secret_access_key: @access_credentials[:secret_access_key]
    )

    File.open(@dataset_path, 'rb') do |file|
      client.put_object(bucket: @backup_location, key: File.basename(@dataset_path), body: file)
    end

    Sublayer.configuration.logger.log(:info, "Successfully backed up dataset to AWS S3")
    "Successfully backed up dataset to AWS S3"
  end

  def backup_to_google
    storage = Google::Cloud::Storage.new(
      project_id: @access_credentials[:project_id],
      credentials: @access_credentials[:credentials]
    )

    bucket = storage.bucket(@backup_location)
    file = bucket.create_file(@dataset_path, File.basename(@dataset_path))

    Sublayer.configuration.logger.log(:info, "Successfully backed up dataset to Google Cloud Storage")
    "Successfully backed up dataset to Google Cloud Storage"
  end

  def backup_to_azure
    blob_client = Azure::Storage::Blob::BlobService.create(
      storage_account_name: @access_credentials[:account_name],
      storage_access_key: @access_credentials[:access_key]
    )

    content = File.open(@dataset_path, "rb") do |file|
      file.read
    end

    blob_client.create_block_blob(@backup_location, File.basename(@dataset_path), content)

    Sublayer.configuration.logger.log(:info, "Successfully backed up dataset to Azure Blobs")
    "Successfully backed up dataset to Azure Blobs"
  end
end
