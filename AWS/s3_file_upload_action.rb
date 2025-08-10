require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action enables easy integration with AWS S3 storage for storing files generated
# by AI processes or other workflow outputs.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with bucket_name, file_path, and optional parameters for S3 configuration.
# It returns the S3 object URL of the uploaded file.
#
# Example usage: When you want to store AI-generated files (images, documents, etc.)
# in AWS S3 for persistent storage or sharing.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil, acl: 'private', metadata: {})
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(@file_path)
    @acl = acl
    @metadata = metadata
    
    @client = Aws::S3::Client.new(
      region: ENV['AWS_REGION'] || 'us-east-1',
      credentials: Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
    )
  end

  def call
    begin
      validate_file
      upload_file
      generate_object_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "AWS S3 service error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def validate_file
    unless File.exist?(@file_path)
      error_message = "File not found: #{@file_path}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def upload_file
    File.open(@file_path, 'rb') do |file|
      @client.put_object(
        bucket: @bucket_name,
        key: @s3_key,
        body: file,
        acl: @acl,
        metadata: @metadata
      )
    end
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to S3 bucket #{@bucket_name}")
  end

  def generate_object_url
    "https://#{@bucket_name}.s3.amazonaws.com/#{@s3_key}"
  end
end