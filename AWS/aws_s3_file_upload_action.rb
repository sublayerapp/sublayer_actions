require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action allows for integrating AWS S3 storage capabilities into Sublayer workflows.
# It is initialized with a bucket_name, file_path, and object_key.
# It returns the public URL of the uploaded file.
#
# Example usage: When you need to store or share generated files via AWS S3.

class AwsS3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, object_key:, region: 'us-east-1')
    @bucket_name = bucket_name
    @file_path = file_path
    @object_key = object_key
    @region = region
    @s3_client = Aws::S3::Client.new(region: @region)
  end

  def call
    upload_file_to_s3
  rescue Aws::S3::Errors::ServiceError => e
    error_message = "Failed to upload file to S3: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "An error occurred: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def upload_file_to_s3
    begin
      @s3_client.put_object(
        bucket: @bucket_name,
        key: @object_key,
        body: File.open(@file_path)
      )
      public_url = "https://#{@bucket_name}.s3.amazonaws.com/#{@object_key}"
      Sublayer.configuration.logger.log(:info, "File uploaded successfully to #{public_url}")
      public_url
    rescue Errno::ENOENT => e
      error_message = "File not found: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
