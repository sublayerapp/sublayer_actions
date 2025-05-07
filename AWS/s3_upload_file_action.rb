require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action enables easy integration with AWS S3 storage for storing AI-generated content,
# processed files, or any other data that needs to be persisted in cloud storage.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with the bucket_name, file_path, and optional parameters for S3 configuration.
# It returns the URL of the uploaded file on successful upload.
#
# Example usage: When you want to store AI-generated content, such as documents or images,
# in AWS S3 for later retrieval or sharing.

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
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def call
    begin
      validate_file
      upload_file
      generate_url
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