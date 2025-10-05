require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to Amazon S3.
# This action allows easy integration with AWS S3 storage service for storing AI-generated
# content, assets, or data files.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a bucket name, key (file path in S3), and file content.
# It returns the S3 object URL on successful upload.
#
# Example usage: When you want to store AI-generated content (like documents, images, or data files)
# in Amazon S3 for persistence or sharing.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket:, key:, content:, content_type: nil)
    @bucket = bucket
    @key = key
    @content = content
    @content_type = content_type || 'application/octet-stream'
    @client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def call
    begin
      response = upload_to_s3
      object_url = generate_object_url
      
      Sublayer.configuration.logger.log(:info, "Successfully uploaded file to S3: #{object_url}")
      object_url
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

  def upload_to_s3
    @client.put_object(
      bucket: @bucket,
      key: @key,
      body: @content,
      content_type: @content_type
    )
  end

  def generate_object_url
    "https://#{@bucket}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@key}"
  end
end