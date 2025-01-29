require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading a file to a specified AWS S3 bucket.
# This action is suitable for workflows that need to handle large files or want to use cloud storage for generated outputs,
# ensuring persistence and accessibility.
#
# It is initialized with a bucket_name, file_path, and optionally a key (the path inside the bucket where the file will be stored).
# It confirms the upload by returning the public URL of the uploaded file.
#
# Example usage: When you want to upload LLM-generated data or other files to an AWS S3 bucket for storage.

class AwsS3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, key: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @key = key || File.basename(file_path)
    @client = Aws::S3::Client.new(region: ENV['AWS_REGION'],
                                  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                                  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    begin
      upload_file
      file_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    @client.put_object(bucket: @bucket_name, key: @key, body: File.read(@file_path))
    Sublayer.configuration.logger.log(:info, "Successfully uploaded \\#{@file_path} to \\#{@bucket_name}/\\#{@key}")
  end

  def file_url
    "https://\\#{@bucket_name}.s3.amazonaws.com/\\#{@key}"
  end
end
