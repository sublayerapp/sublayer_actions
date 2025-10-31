require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket for backup purposes.
# This action ensures data persistence and security by integrating with AWS S3.
#
# It is initialized with bucket_name, file_path, and optional access_key_id, secret_access_key, and region.
# It uploads the specified file to the given S3 bucket.
#
# Example usage: When you want to back up important data to AWS S3 for redundancy and safe storage.

class DataBackupToS3Action < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil, access_key_id: nil, secret_access_key: nil, region: 'us-east-1')
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(file_path)
    @s3_client = Aws::S3::Client.new(
      access_key_id: access_key_id || ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: secret_access_key || ENV['AWS_SECRET_ACCESS_KEY'],
      region: region
    )
  end

  def call
    upload_file_to_s3
  rescue Aws::S3::Errors::ServiceError => e
    error_message = "Error uploading file to S3: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Unexpected error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def upload_file_to_s3
    File.open(@file_path, 'rb') do |file|
      @s3_client.put_object(
        bucket: @bucket_name,
        key: @s3_key,
        body: file
      )
    end
    Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to #{@bucket_name}/#{@s3_key}")
  end
end
