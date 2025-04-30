require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to a specified AWS S3 bucket. 
# This action facilitates the integration of cloud storage solutions into Sublayer workflows.
#
# It is initialized with a bucket_name, file_path, and optional s3_key. The s3_key represents the location in the bucket.
# It returns the public URL of the uploaded file if successful.
#
# Example usage: When you want to store LLM-generated files in S3 for persistence and further processing.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(file_path)
    @client = Aws::S3::Client.new(region: ENV['AWS_REGION'], access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    begin
      upload_file
      public_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    @client.put_object(bucket: @bucket_name, key: @s3_key, body: File.read(@file_path))
    Sublayer.configuration.logger.log(:info, "File successfully uploaded to S3: #{@bucket_name}/#{@s3_key}")
  end

  def public_url
    "https://#{@bucket_name}.s3.amazonaws.com/#{@s3_key}"
  end
end
