require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action facilitates storing large outputs from AI processes or logs in cloud storage.
#
# It is initialized with a bucket name, file path, and file content.
# It returns a success message upon successfully uploading the file.
#
# Example usage: When you want to store generated data or log files in an AWS S3 bucket.

class AwsS3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, file_content:)
    @bucket_name = bucket_name
    @file_path = file_path
    @file_content = file_content
    @s3_client = Aws::S3::Client.new(region: 'us-east-1') # Use appropriate region
  end

  def call
    begin
      upload_file
      Sublayer.configuration.logger.log(:info, "File successfully uploaded to #{@bucket_name}/#{@file_path}")
      "File successfully uploaded to #{@bucket_name}/#{@file_path}"
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Failed to upload file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    @s3_client.put_object(
      bucket: @bucket_name,
      key: @file_path,
      body: @file_content
    )
  end
end