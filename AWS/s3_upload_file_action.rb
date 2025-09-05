require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action enables easy integration with AWS S3 storage for files generated in Sublayer workflows,
# such as AI-generated content, reports, or processed data files.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with bucket_name, file_path, s3_key, and optional parameters for permissions and metadata.
# It returns the S3 object URL on successful upload.
#
# Example usage: When you need to store AI-generated files, documents, or images in cloud storage.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key:, acl: 'private', metadata: {}, content_type: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key
    @acl = acl
    @metadata = metadata
    @content_type = content_type
    
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
    upload_options = {
      bucket: @bucket_name,
      key: @s3_key,
      body: File.open(@file_path, 'rb'),
      acl: @acl,
      metadata: @metadata
    }

    # Add content_type if specified
    upload_options[:content_type] = @content_type if @content_type

    @client.put_object(upload_options)
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to S3 bucket #{@bucket_name} with key #{@s3_key}")
  end

  def generate_object_url
    bucket = Aws::S3::Bucket.new(
      name: @bucket_name,
      client: @client
    )
    object = bucket.object(@s3_key)
    object.public_url
  end
end