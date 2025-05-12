require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action enables storing files (like AI-generated content or processed data) in S3 buckets,
# making them accessible via URLs and integrating with cloud-based workflows.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with bucket_name, file_path (local), and s3_key (destination path in S3).
# Optionally accepts content_type and acl settings.
# Returns the URL of the uploaded file in S3.
#
# Example usage: When you want to upload AI-generated images or documents to S3
# for persistent storage and URL-based access.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key:, content_type: nil, acl: 'private')
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key
    @content_type = content_type
    @acl = acl
    @client = Aws::S3::Client.new(
      region: ENV['AWS_REGION'] || 'us-east-1',
      credentials: Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
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
      key: @s3_key,
      body: File.open(@file_path, 'rb'),
      acl: @acl
    }

    # Add content_type if specified
    options[:content_type] = @content_type if @content_type

    @client.put_object(options)
    
    Sublayer.configuration.logger.log(
      :info,
      "Successfully uploaded #{@file_path} to S3 bucket #{@bucket_name} at #{@s3_key}"
    )
  end

  def generate_url
    if @acl == 'public-read'
      "https://#{@bucket_name}.s3.amazonaws.com/#{@s3_key}"
    else
      presigner = Aws::S3::Presigner.new(client: @client)
      presigner.presigned_url(
        :get_object,
        bucket: @bucket_name,
        key: @s3_key,
        expires_in: 3600 # URL valid for 1 hour
      )
    end
  end
end