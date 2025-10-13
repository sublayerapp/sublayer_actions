require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action provides a simple interface to store files in Amazon S3 cloud storage,
# making it ideal for workflows that generate files that need cloud persistence.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with bucket_name, file_path (the S3 key/path), and file_content.
# It returns the URL of the uploaded file on successful upload.
#
# Example usage: When you want to store AI-generated content (like images or documents)
# in AWS S3 for later access or distribution.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, file_content:, content_type: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @file_content = file_content
    @content_type = content_type || determine_content_type
    @client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def call
    begin
      upload_to_s3
      generate_file_url
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

  def upload_to_s3
    @client.put_object(
      bucket: @bucket_name,
      key: @file_path,
      body: @file_content,
      content_type: @content_type
    )
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded file to S3: #{@file_path}")
  end

  def generate_file_url
    "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{URI.encode_www_form_component(@file_path)}"
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
    when '.html'
      'text/html'
    else
      'application/octet-stream'
    end
  end
end