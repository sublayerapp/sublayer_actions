require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action handles the upload of files to specified S3 buckets with optional metadata
# and permission settings. It's particularly useful for storing AI-generated content,
# reports, or any files that need cloud storage.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with the file path, bucket name, and optional parameters for
# S3 object key, permissions, and metadata.
# It returns the URL of the uploaded file on success.
#
# Example usage: When you want to store LLM-generated documents, reports,
# or AI-generated images in AWS S3 for later access.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(file_path:, bucket:, key: nil, acl: 'private', metadata: {})
    @file_path = file_path
    @bucket = bucket
    @key = key || File.basename(file_path)
    @acl = acl
    @metadata = metadata
    
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
      generate_url
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
      error_message = "File not found at path: #{@file_path}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def upload_file
    File.open(@file_path, 'rb') do |file|
      @client.put_object(
        bucket: @bucket,
        key: @key,
        body: file,
        acl: @acl,
        metadata: @metadata
      )
    end
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to S3 bucket #{@bucket}")
  end

  def generate_url
    if @acl == 'public-read'
      "https://#{@bucket}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@key}"
    else
      @client.get_object(
        bucket: @bucket,
        key: @key
      ).presigned_url(:get, expires_in: 3600)
    end
  end
end