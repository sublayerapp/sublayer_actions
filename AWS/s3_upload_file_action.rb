require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to Amazon S3.
# This action provides a simple interface for storing files in S3 buckets,
# making it useful for persisting AI-generated content, images, or other artifacts.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with:
# - bucket_name: The name of the S3 bucket
# - file_path: Local path to the file to upload
# - s3_key: The desired path/name for the file in S3
# - content_type: Optional MIME type of the file (auto-detected if not provided)
#
# Returns the URL of the uploaded file in S3.
#
# Example usage: When you want to store AI-generated content or files in S3:
# ```ruby
# action = S3UploadFileAction.new(
#   bucket_name: 'my-ai-artifacts',
#   file_path: './generated_image.png',
#   s3_key: 'images/generated_image.png'
# )
# s3_url = action.call
# ```

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key:, content_type: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key
    @content_type = content_type
    
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
      generate_url
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

  def validate_file!
    unless File.exist?(@file_path)
      raise StandardError, "File not found: #{@file_path}"
    end
  end

  def upload_file
    options = {
      bucket: @bucket_name,
      key: @s3_key,
      body: File.open(@file_path),
      content_type: determine_content_type
    }

    @client.put_object(options)
    
    Sublayer.configuration.logger.log(
      :info,
      "Successfully uploaded #{@file_path} to S3 bucket #{@bucket_name} at #{@s3_key}"
    )
  end

  def determine_content_type
    return @content_type if @content_type
    
    # Simple MIME type detection based on file extension
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

  def generate_url
    "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@s3_key}"
  end
end