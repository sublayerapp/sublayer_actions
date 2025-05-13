require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to a specified AWS S3 bucket.
# This action allows for seamless integration of cloud storage for generated files or backups.

class AwsS3FileUploaderAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, file_key:, region: 'us-east-1')
    @bucket_name = bucket_name
    @file_path = file_path
    @file_key = file_key
    @region = region
    @s3_client = Aws::S3::Client.new(region: @region)
    @logger = Sublayer.configuration.logger
  end

  def call
    upload_file
  rescue Aws::S3::Errors::ServiceError => e
    error_message = "Error uploading file to S3: #{e.message}"
    @logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    @logger.log(:error, "Unexpected error: #{e.message}")
    raise e
  end

  private

  def upload_file
    File.open(@file_path, 'rb') do |file|
      @s3_client.put_object(bucket: @bucket_name, key: @file_key, body: file)
      @logger.log(:info, "File uploaded successfully to bucket #{@bucket_name} with key #{@file_key}")
    end
  end
end