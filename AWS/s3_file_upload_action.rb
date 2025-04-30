require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to Amazon S3 buckets.
# This action allows easy integration with AWS S3 for storing generated documents, images,
# or other data produced by AI processes in cloud storage for later retrieval or sharing.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a bucket_name, file_path, and optional s3_key (defaults to the file name).
# It returns the S3 object key of the uploaded file.
#
# Example usage: When you want to store AI-generated content (e.g., documents, images) in AWS S3.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(@file_path)
    @client = Aws::S3::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def call
    begin
      File.open(@file_path, 'rb') do |file|
        @client.put_object(
          bucket: @bucket_name,
          key: @s3_key,
          body: file
        )
      end
      Sublayer.configuration.logger.log(:info, "File uploaded successfully to S3: #{@s3_key}")
      @s3_key
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Errno::ENOENT => e
      error_message = "Error: File not found - #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end