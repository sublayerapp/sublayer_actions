require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading a file to an AWS S3 bucket.
# This action provides a simple interface for storing files in Amazon S3 cloud storage.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with bucket_name, file_path (the destination path in S3), and file_content.
# It returns the S3 object URL of the uploaded file.
#
# Example usage: When you want to store AI-generated content, reports, or processed files in S3.
# Particularly useful for persisting outputs from LLM processing or storing generated artifacts.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, file_content:)
    @bucket_name = bucket_name
    @file_path = file_path
    @file_content = file_content
    @client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def call
    begin
      upload_to_s3
      generate_object_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error during S3 upload: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def upload_to_s3
    @client.put_object(
      bucket: @bucket_name,
      key: @file_path,
      body: @file_content
    )
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded file to S3: #{@bucket_name}/#{@file_path}")
  end

  def generate_object_url
    "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@file_path}"
  end
end