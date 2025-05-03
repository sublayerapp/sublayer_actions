require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3 buckets.
# This action enables easy integration with AWS S3 storage within Sublayer workflows.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with:
# - bucket_name: The name of the S3 bucket to upload to
# - file_path: Local path of the file to upload
# - s3_key: The desired path/name for the file in S3 (if not provided, uses the file's basename)
# - content_type: Optional MIME type of the file (if not provided, will be guessed from the file extension)
#
# Returns the URL of the uploaded file in S3.
#
# Example usage: When you want to upload AI-generated files (like DALL-E images or generated documents)
# to S3 for persistent storage and sharing.

class AwsS3UploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil, content_type: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(@file_path)
    @content_type = content_type || guess_content_type
    
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
      @client.put_object(
        bucket: @bucket_name,
        key: @s3_key,
        body: file,
        content_type: @content_type
      )
    end
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to S3 bucket #{@bucket_name} as #{@s3_key}")
  end

  def generate_url
    "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{URI.encode_www_form_component(@s3_key)}"
  end

  def guess_content_type
    case File.extname(@file_path).downcase
    when '.jpg', '.jpeg'
      'image/jpeg'
    when '.png'
      'image/png'
    when '.gif'
      'image/gif'
    when '.pdf'
      'application/pdf'
    when '.txt'
      'text/plain'
    when '.json'
      'application/json'
    else
      'application/octet-stream'
    end
  end
end