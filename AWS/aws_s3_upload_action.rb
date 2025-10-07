require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading a file to an AWS S3 bucket.
# This action streamlines the process of integrating AWS S3 storage solutions into Sublayer tasks.
#
# It is initialized with a bucket_name, file_path, and s3_key, where:
# - bucket_name is the S3 bucket where the file will be uploaded.
# - file_path is the local path of the file to be uploaded.
# - s3_key is the key (path inside the bucket) for the uploaded file.
#
# Example usage: When you want to upload a file to S3 based on results from an AI-driven process in Sublayer.

class AWSS3UploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key:)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'])
  end

  def call
    begin
      upload_file_to_s3
      Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to #{@bucket_name}/#{@s3_key}")
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "S3 upload failed: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file_to_s3
    File.open(@file_path, 'rb') do |file|
      @s3_client.put_object(bucket: @bucket_name, key: @s3_key, body: file)
    end
  end
end
