require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to Amazon S3 buckets.
# This action simplifies the process of storing files in S3, handling mime-types,
# access controls, and optional server-side encryption.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with bucket_name, file_path, and optional parameters for S3 configuration.
# It returns the S3 object URL of the uploaded file.
#
# Example usage: When you want to store AI-generated assets, backups, or processed data in S3.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil, acl: 'private', encryption: false, content_type: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(@file_path)
    @acl = acl
    @encryption = encryption
    @content_type = content_type || determine_content_type
    
    @client = Aws::S3::Client.new(
      region: ENV['AWS_REGION'] || 'us-east-1',
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def call
    begin
      validate_file
      upload_file
      generate_object_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "S3 service error: #{e.message}"
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
      body: File.read(@file_path),
      acl: @acl,
      content_type: @content_type
    }

    # Add server-side encryption if requested
    options[:server_side_encryption] = 'AES256' if @encryption

    @client.put_object(options)
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to S3 bucket #{@bucket_name}")
  end

  def generate_object_url
    "https://#{@bucket_name}.s3.#{@client.config.region}.amazonaws.com/#{@s3_key}"
  end

  def determine_content_type
    case File.extname(@file_path).downcase
    when '.jpg', '.jpeg'
      'image/jpeg'
    when '.png'
      'image/png'
    when '.gif'
      'image/gif'
    when '.pdf'
      'application/pdf'
    when '.json'
      'application/json'
    when '.txt'
      'text/plain'
    else
      'application/octet-stream'
    end
  end
end