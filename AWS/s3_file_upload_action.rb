require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action enables workflows to store generated files (like AI outputs, images, PDFs)
# in AWS S3 cloud storage for later access or distribution.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with:
# - bucket_name: The name of the S3 bucket
# - file_path: Local path to the file to upload
# - s3_key: The desired path/name for the file in S3
# - acl: Optional access control (default: private)
#
# It returns the URL of the uploaded file in S3.
#
# Example usage: When you want to store AI-generated content, like DALL-E images
# or generated PDFs, in cloud storage for later access.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key:, acl: 'private')
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key
    @acl = acl
    
    @client = Aws::S3::Client.new(
      region: ENV['AWS_REGION'],
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
      error_message = "AWS S3 error during file upload: #{e.message}"
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
        bucket: @bucket_name,
        key: @s3_key,
        body: file,
        acl: @acl
      )
    end
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to S3 bucket #{@bucket_name} at #{@s3_key}")
  end

  def generate_url
    "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@s3_key}"
  end
end