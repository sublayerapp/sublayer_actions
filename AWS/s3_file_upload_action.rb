require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action allows AI workflows to store generated outputs securely in AWS S3 for scalability and accessibility.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a bucket_name, file_path (local), key (remote S3 path), and optional content_type.
# It returns the public URL of the uploaded file for verification purposes or further processing.
#
# Example usage: When you want to store AI-generated data or results that must be accessed by other subsystems or users.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, key:, content_type: 'application/octet-stream')
    @bucket_name = bucket_name
    @file_path = file_path
    @key = key
    @content_type = content_type
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'], access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    begin
      upload_file
      file_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
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
        body: file,
        content_type: @content_type
      )
    end
    Sublayer.configuration.logger.log(:info, "Successfully uploaded file to S3 bucket #{@bucket_name} with key #{@key}")
  end

  def file_url
    Aws::S3::Object.new(@bucket_name, @key, client: @s3_client).public_url
  end
end