require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading a file to an AWS S3 bucket.
# This action enables easy file uploads to S3 storage, making it useful for persisting
# generated files or making them publicly accessible.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with bucket_name, file_path, and optional s3_key and metadata.
# It returns the S3 object URL of the uploaded file.
#
# Example usage: When you want to upload LLM-generated files, reports, or any other content
# to S3 for storage or public access.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil, metadata: {})
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(@file_path)
    @metadata = metadata
    @client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def call
    begin
      validate_file!
      upload_file
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

  def validate_file!
    unless File.exist?(@file_path)
      error_message = "File not found at path: #{@file_path}"
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

      object_url = "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@s3_key}"
      Sublayer.configuration.logger.log(:info, "File successfully uploaded to S3: #{object_url}")
      
      object_url
    end
  end
end