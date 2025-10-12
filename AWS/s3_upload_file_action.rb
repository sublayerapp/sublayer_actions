require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action enables easy integration with AWS S3 storage for files generated or processed
# in AI workflows, such as generated images, documents, or other data files.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with:
# - bucket_name: The name of the S3 bucket to upload to
# - file_path: Local path to the file to upload
# - s3_key: The desired path/name for the file in S3
# - acl: Access control (defaults to private)
# - metadata: Optional metadata hash for the file
#
# Returns the URL of the uploaded file in S3.
#
# Example usage: When you want to upload AI-generated files to S3 for storage and distribution.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key:, acl: 'private', metadata: {})
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key
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
        metadata: @metadata
      )
    end
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to S3 bucket #{@bucket_name} at #{@s3_key}")
  end

  def generate_url
    bucket = Aws::S3::Bucket.new(
      name: @bucket_name,
      client: @client
    )
    
    object = bucket.object(@s3_key)
    object.public_url
  end
end