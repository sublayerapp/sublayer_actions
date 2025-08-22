require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading a file to an AWS S3 bucket.
# This action enables easy file storage in AWS S3 for persisting generated content or data.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a bucket_name, file_path, and s3_key (destination path),
# with optional metadata and content_type parameters.
# It returns the S3 object URL of the uploaded file.
#
# Example usage: When you want to store AI-generated content, reports, or any other
# files in AWS S3 as part of your workflow.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key:, metadata: {}, content_type: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key
    @metadata = metadata
    @content_type = content_type || detect_content_type
    @client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def call
    begin
      validate_file
      upload_file
      generate_object_url
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
        metadata: @metadata,
        content_type: @content_type
      )
    end
    
    Sublayer.configuration.logger.log(:info, "File successfully uploaded to S3: #{@s3_key}")
  end

  def generate_object_url
    "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@s3_key}"
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