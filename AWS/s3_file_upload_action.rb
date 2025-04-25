require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action enables easy file uploads to S3 buckets within Sublayer workflows,
# making it useful for persisting files or making them publicly accessible.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a file_path, bucket_name, and optional parameters for S3 path and ACL.
# It returns the S3 URL of the uploaded file.
#
# Example usage: When you want to upload LLM-generated files, images, or other content to S3
# for storage or public access.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(file_path:, bucket_name:, s3_path: nil, acl: 'private')
    @file_path = file_path
    @bucket_name = bucket_name
    @s3_path = s3_path || File.basename(@file_path)
    @acl = acl
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
    File.open(@file_path, 'rb') do |file|
      @client.put_object(
        bucket: @bucket_name,
        key: @s3_path,
        body: file,
        acl: @acl
      )
    end
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to S3 bucket #{@bucket_name}")
  end

  def generate_url
    if @acl == 'public-read'
      "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@s3_path}"
    else
      @client.get_object(
        bucket: @bucket_name,
        key: @s3_path
      ).presigned_url(:get, expires_in: 3600)
    end
  end
end