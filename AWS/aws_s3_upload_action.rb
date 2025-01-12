require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action allows for easy integration with AWS S3 storage, enabling data persistence
# for AI-generated files, backups, or any other data that needs cloud storage.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a bucket_name, file_path, and optional s3_key.
# It returns the S3 object key of the uploaded file.
#
# Example usage: When you want to store AI-generated files, backups, or any other data in AWS S3.

class AwsS3UploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(@file_path)
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
    rescue StandardError => e
      error_message = "Unexpected error uploading file to S3: #{e.message}"
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
        body: file
      )
    end
  end
end
