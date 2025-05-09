require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action allows for easy integration with AWS S3, enabling remote storage of files.
#
# It is initialized with a bucket_name and file_path, along with optional key and region parameters.
# On successful execution, it uploads the file to the specified S3 bucket.
#
# Example usage: When you want to upload LLM-generated data to an S3 bucket for backup or remote access.

class AWSS3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, key: nil, region: 'us-east-1')
    @bucket_name = bucket_name
    @file_path = file_path
    @key = key || File.basename(file_path)
    @s3_client = Aws::S3::Client.new(region: region)
  end

  def call
    begin
      upload_file
      Sublayer.configuration.logger.log(:info, "Successfully uploaded \\#{@file_path} to S3 bucket \\#{@bucket_name} as \\#{@key}")
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    File.open(@file_path, 'rb') do |file|
      @s3_client.put_object(
        bucket: @bucket_name,
        key: @key,
        body: file
      )
    end
  end
end
