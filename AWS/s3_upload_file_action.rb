require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action allows for easy integration with AWS S3 storage, enabling storage
# of AI-generated assets, backups, or processed data in the cloud.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with bucket_name, file_path, s3_key, and optional metadata.
# It returns the S3 object URL on successful upload.
#
# Example usage: When you want to store AI-generated files, backups, or processed
# data in AWS S3 for later retrieval or distribution.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key:, metadata: {})
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key
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
      response = @client.put_object(
        bucket: @bucket_name,
        key: @s3_key,
        body: file,
        metadata: @metadata
      )

      if response.etag
        object_url = generate_object_url
        Sublayer.configuration.logger.log(:info, "File successfully uploaded to S3: #{object_url}")
        return object_url
      else
        error_message = 'Upload completed but no ETag received'
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    end
  end

  def generate_object_url
    "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@s3_key}"
  end
end