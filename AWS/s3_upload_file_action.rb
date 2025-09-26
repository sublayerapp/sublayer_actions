require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action enables easy integration with AWS S3 storage for files generated in AI workflows.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with the file path, bucket name, and S3 object key (path).
# Optional parameters include metadata and ACL settings.
# Returns the S3 object URL on successful upload.
#
# Example usage: When you need to store AI-generated files (reports, images, etc.)
# in S3 for persistent storage or sharing.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(file_path:, bucket:, s3_key:, metadata: {}, acl: 'private')
    @file_path = file_path
    @bucket = bucket
    @s3_key = s3_key
    @metadata = metadata
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
      upload_to_s3
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

  def upload_to_s3
    File.open(@file_path, 'rb') do |file|
      response = @client.put_object(
        bucket: @bucket,
        key: @s3_key,
        body: file,
        metadata: @metadata,
        acl: @acl
      )

      object_url = "https://#{@bucket}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@s3_key}"
      Sublayer.configuration.logger.log(:info, "Successfully uploaded file to S3: #{object_url}")
      
      object_url
    end
  end
end