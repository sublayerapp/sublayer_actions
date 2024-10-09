require 'aws-sdk-s3'

# Description: Sublayer::Action for interacting with AWS S3.
# Allows uploading and downloading files to/from S3 buckets.
#
# Example usage:
# - Uploading generated reports to S3
# - Downloading training data for AI models

class AwsS3Action < Sublayer::Actions::Base
  def initialize(bucket_name:, region: 'us-east-1', access_key_id: nil, secret_access_key: nil)
    @bucket_name = bucket_name
    @region = region
    @access_key_id = access_key_id || ENV['AWS_ACCESS_KEY_ID']
    @secret_access_key = secret_access_key || ENV['AWS_SECRET_ACCESS_KEY']

    @s3_client = Aws::S3::Client.new(
      region: @region,
      access_key_id: @access_key_id,
      secret_access_key: @secret_access_key
    )
  end

  def upload_file(local_file_path:, s3_key:)
    begin
      @s3_client.put_object(
        bucket: @bucket_name,
        key: s3_key,
        body: File.read(local_file_path)
      )
      Sublayer.configuration.logger.info("Uploaded '#{local_file_path}' to 's3://#{@bucket_name}/#{s3_key}'")
    rescue Aws::S3::Errors::ServiceError => e
      Sublayer.configuration.logger.error("Error uploading file: #{e.message}")
      raise e
    end
  end

  def download_file(s3_key:, local_file_path:)
    begin
      @s3_client.get_object(
        response_target: local_file_path,
        bucket: @bucket_name,
        key: s3_key
      )
      Sublayer.configuration.logger.info("Downloaded 's3://#{@bucket_name}/#{s3_key}' to '#{local_file_path}'")
    rescue Aws::S3::Errors::ServiceError => e
      Sublayer.configuration.logger.error("Error downloading file: #{e.message}")
      raise e
    end
  end
end