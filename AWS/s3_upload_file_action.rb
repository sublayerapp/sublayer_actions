require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading a file to an AWS S3 bucket.
# This action provides a simple interface for storing files in S3 cloud storage,
# which can be useful for persisting AI-generated content, backups, or processed files.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with the bucket name, file path, and the target key (path) in S3.
# Optional parameters include AWS credentials and region (defaults to environment variables).
# It returns the S3 object URL of the uploaded file.
#
# Example usage: When you want to store LLM-generated content, processed files,
# or backups in AWS S3 as part of your AI workflow.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket:, file_path:, s3_key:, region: nil, access_key_id: nil, secret_access_key: nil)
    @bucket = bucket
    @file_path = file_path
    @s3_key = s3_key
    @region = region || ENV['AWS_REGION'] || 'us-east-1'
    @access_key_id = access_key_id || ENV['AWS_ACCESS_KEY_ID']
    @secret_access_key = secret_access_key || ENV['AWS_SECRET_ACCESS_KEY']
    
    validate_inputs
    initialize_s3_client
  end

  def call
    begin
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

  def validate_inputs
    raise ArgumentError, 'Bucket name cannot be empty' if @bucket.nil? || @bucket.empty?
    raise ArgumentError, 'File path cannot be empty' if @file_path.nil? || @file_path.empty?
    raise ArgumentError, 'S3 key cannot be empty' if @s3_key.nil? || @s3_key.empty?
    raise ArgumentError, 'File does not exist' unless File.exist?(@file_path)
  end

  def initialize_s3_client
    @s3_client = Aws::S3::Client.new(
      region: @region,
      access_key_id: @access_key_id,
      secret_access_key: @secret_access_key
    )
  end

  def upload_file
    File.open(@file_path, 'rb') do |file|
      response = @s3_client.put_object(
        bucket: @bucket,
        key: @s3_key,
        body: file
      )

      if response.etag
        object_url = "https://#{@bucket}.s3.#{@region}.amazonaws.com/#{@s3_key}"
        Sublayer.configuration.logger.log(:info, "Successfully uploaded file to S3: #{object_url}")
        return object_url
      else
        raise StandardError, 'Upload completed but no ETag received'
      end
    end
  end
end