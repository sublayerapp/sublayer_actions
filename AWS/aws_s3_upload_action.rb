require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to Amazon S3 buckets.
# This action enables easy storage and sharing of AI-generated content or processed data.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with bucket_name, file_path, and optional s3_key and content_type.
# It returns the S3 object key of the uploaded file.
#
# Example usage: When you want to upload AI-generated files or processed data to Amazon S3 for storage or sharing.

class AWSS3UploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil, content_type: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(@file_path)
    @content_type = content_type
    @s3_client = Aws::S3::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def call
    begin
      upload_file
      Sublayer.configuration.logger.log(:info, "File successfully uploaded to S3: #{@s3_key}")
      @s3_key
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
        key: @s3_key,
        body: file,
        content_type: @content_type
      )
    end
  end
end