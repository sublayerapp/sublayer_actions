require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action simplifies the process of storing files in S3 with configurable options for
# metadata, ACL permissions, and content type handling.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with:
# - bucket_name: The name of the S3 bucket
# - file_path: Local path to the file to upload
# - s3_key: The desired path/name in S3
# Optional parameters:
# - acl: Access control (private, public-read, etc.)
# - metadata: Hash of metadata to attach to the object
# - content_type: The MIME type of the file
#
# Example usage: When you need to store AI-generated content (images, documents, etc.)
# in S3 for later access or distribution.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key:, acl: 'private', metadata: {}, content_type: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key
    @acl = acl
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
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "S3 service error during upload: #{e.message}"
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
    upload_params = {
      bucket: @bucket_name,
      key: @s3_key,
      body: File.open(@file_path, 'rb'),
      acl: @acl,
      metadata: @metadata,
      content_type: @content_type
    }

    response = @client.put_object(upload_params)
    
    object_url = "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@s3_key}"
    Sublayer.configuration.logger.log(:info, "File successfully uploaded to S3: #{object_url}")
    
    object_url
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
    when '.json'
      'application/json'
    when '.txt'
      'text/plain'
    else
      'application/octet-stream'
    end
  end
end