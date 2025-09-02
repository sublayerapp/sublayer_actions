require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to Amazon S3.
# This action provides a simple interface for uploading files to S3 with support for
# metadata, permissions, and custom paths.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with the bucket name, file path, and various optional parameters
# for customizing the upload. It returns the URL of the uploaded file.
#
# Example usage: When you need to store AI-generated files (images, documents, etc.)
# in cloud storage for later access or distribution.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(
    bucket:,
    file_path:,
    s3_key: nil,
    acl: 'private',
    metadata: {},
    content_type: nil,
    region: ENV['AWS_REGION'] || 'us-east-1'
  )
    @bucket = bucket
    @file_path = file_path
    @s3_key = s3_key || File.basename(@file_path)
    @acl = acl
    @metadata = metadata
    @content_type = content_type
    @region = region

    @client = Aws::S3::Client.new(
      region: @region,
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def call
    begin
      upload_file
      generate_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "S3 upload error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def upload_file
    options = {
      bucket: @bucket,
      key: @s3_key,
      body: File.open(@file_path, 'rb'),
      acl: @acl,
      metadata: @metadata
    }

    # Add content_type if specified
    options[:content_type] = @content_type if @content_type

    @client.put_object(options)
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to S3 bucket #{@bucket} at key #{@s3_key}")
  end

  def generate_url
    "https://#{@bucket}.s3.#{@region}.amazonaws.com/#{@s3_key}"
  end
end