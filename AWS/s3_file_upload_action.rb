require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to Amazon S3.
# This action enables easy integration with AWS S3 storage for storing files generated 
# by AI processes or needed in AI workflows.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with the file path, S3 bucket, and optional parameters for S3 path and metadata.
# It returns the S3 object URL of the uploaded file.
#
# Example usage: When you want to store AI-generated files (images, documents, data) in S3,
# or when you need to upload files that will be processed by AI workflows.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(file_path:, bucket:, s3_path: nil, metadata: {})
    @file_path = file_path
    @bucket = bucket
    @s3_path = s3_path || File.basename(@file_path)
    @metadata = metadata
    
    @client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION'] || 'us-east-1'
    )
  end

  def call
    begin
      validate_file
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
        bucket: @bucket,
        key: @s3_path,
        body: file,
        metadata: @metadata
      )

      object_url = generate_object_url
      Sublayer.configuration.logger.log(:info, "Successfully uploaded file to S3: #{object_url}")
      object_url
    end
  end

  def generate_object_url
    "https://#{@bucket}.s3.#{@client.config.region}.amazonaws.com/#{@s3_path}"
  end
end