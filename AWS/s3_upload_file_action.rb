require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action enables easy file uploads to S3 buckets with configurable ACL and metadata,
# making it ideal for storing AI-generated assets like documents, images, or any other files.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# Environment variables needed:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - AWS_REGION (optional, defaults to 'us-east-1')
#
# It is initialized with bucket_name, file_path, and optional parameters for S3 configuration.
# It returns the URL of the uploaded file on successful upload.
#
# Example usage: When you want to persist AI-generated content (like DALL-E images or GPT
# generated documents) to cloud storage for later retrieval.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil, acl: 'private', metadata: {}, content_type: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(@file_path)
    @acl = acl
    @metadata = metadata
    @content_type = content_type || detect_content_type
    
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
      generate_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "AWS S3 error: #{e.message}"
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
        metadata: @metadata,
        content_type: @content_type
      )
    end

    Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to S3 bucket #{@bucket_name}")
  end

  def generate_url
    "https://#{@bucket_name}.s3.amazonaws.com/#{@s3_key}"
  end

  def detect_content_type
    case File.extname(@file_path).downcase
    when '.jpg', '.jpeg'
      'image/jpeg'
    when '.png'
      'image/png'
    when '.gif'
      'image/gif'
    when '.pdf'
      'application/pdf'
    when '.txt'
      'text/plain'
    when '.json'
      'application/json'
    else
      'application/octet-stream'
    end
  end
end