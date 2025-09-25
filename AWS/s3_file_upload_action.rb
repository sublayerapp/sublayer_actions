require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action enables easy integration with AWS S3 storage in Sublayer workflows,
# particularly useful for storing LLM-generated content or files in cloud storage.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with bucket_name, file_path, and various optional S3 parameters.
# It returns the URL of the uploaded file on successful upload.
#
# Example usage: When you want to upload LLM-generated content or processed files to S3
# for storage or sharing.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, key: nil, acl: 'private', metadata: {}, encryption: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @key = key || File.basename(@file_path)
    @acl = acl
    @metadata = metadata
    @encryption = encryption
    
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
    options = {
      bucket: @bucket_name,
      key: @key,
      body: File.open(@file_path),
      acl: @acl,
      metadata: @metadata
    }

    # Add server-side encryption if specified
    if @encryption
      options[:server_side_encryption] = @encryption
    end

    @client.put_object(options)
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to S3 bucket #{@bucket_name}")
  end

  def generate_url
    "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@key}"
  end
end