require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to a specified AWS S3 bucket.
# This action is designed to provide a scalable solution for storing large volumes of data generated from AI applications.
#
# It is initialized with the bucket_name, file_path, and optionally, the key (file name in the bucket).
# It logs the success or failure of the file upload.
#
# Example usage: Use this action to upload AI-generated files or data to S3 for storage or further processing.

class AwsS3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, key: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @key = key || File.basename(file_path)
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'], access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    upload_file_to_s3
  rescue Aws::Errors::ServiceError => e
    error_message = "Error uploading file to S3: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def upload_file_to_s3
    File.open(@file_path, 'rb') do |file|
      @s3_client.put_object(bucket: @bucket_name, key: @key, body: file)
    end
    Sublayer.configuration.logger.log(:info, "File uploaded successfully to bucket #{@bucket_name} with key #{@key}")
  end
end
