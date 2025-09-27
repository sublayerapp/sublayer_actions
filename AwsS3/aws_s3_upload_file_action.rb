# Description: Sublayer::Action responsible for uploading a file to a specified bucket in AWS S3.
# This action allows for easy integration with AWS S3 for file storage and retrieval within a Sublayer workflow.
#
# It is initialized with a bucket_name, file_path (local path to the file), and optionally content_type (e.g., 'image/jpeg', 'text/plain').
# On successful execution, it uploads the file to the specified S3 bucket.
#
# Example usage: When you want to upload LLM-generated images or text files to AWS S3 for later use or distribution.

require 'aws-sdk-s3'

class AwsS3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, content_type: 'application/octet-stream')
    @bucket_name = bucket_name
    @file_path = file_path
    @content_type = content_type
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'])
  end

  def call
    begin
      upload_file
      Sublayer.configuration.logger.log(:info, "Successfully uploaded \#{@file_path} to S3 bucket \#{@bucket_name}")
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Errno::ENOENT => e
      error_message = "File not found: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error uploading file to S3: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    file = File.open(@file_path, 'rb')
    @s3_client.put_object(
      bucket: @bucket_name,
      key: File.basename(@file_path),
      body: file,
      content_type: @content_type
    )
  ensure
      file.close if file
  end
end
