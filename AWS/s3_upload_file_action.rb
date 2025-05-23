require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading a file to an AWS S3 bucket.
# This action provides a simple interface for storing files in S3 with specified paths and permissions.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with:
# - bucket_name: The name of the S3 bucket
# - file_path: Local path to the file to be uploaded
# - s3_key: The desired path/key in S3 where the file will be stored
# - acl: (optional) The ACL for the uploaded file (default: 'private')
#
# Returns: The S3 object URL of the uploaded file
#
# Example usage: When you want to store AI-generated files, backups, or any other files
# in AWS S3 as part of your workflow.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key:, acl: 'private')
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key
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
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "AWS S3 error during upload: #{e.message}"
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
      response = @client.put_object(
        bucket: @bucket_name,
        key: @s3_key,
        body: file,
        acl: @acl
      )

      object_url = "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@s3_key}"
      Sublayer.configuration.logger.log(:info, "Successfully uploaded file to S3: #{object_url}")
      
      object_url
    end
  end
end