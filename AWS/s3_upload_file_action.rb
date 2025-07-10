require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action enables easy integration with AWS S3 storage for storing files generated
# by AI workflows, such as reports, images, or processed data.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with the bucket name, file path, and content, with optional metadata and storage class.
# It returns the S3 object URL of the uploaded file.
#
# Example usage: When you want to store AI-generated content (like reports or images)
# in S3 for later retrieval or sharing.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket:, file_path:, content:, metadata: {}, storage_class: 'STANDARD')
    @bucket = bucket
    @file_path = file_path
    @content = content
    @metadata = metadata
    @storage_class = storage_class
    @client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def call
    begin
      upload_to_s3
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
      key: @file_path,
      body: @content,
      metadata: @metadata,
      storage_class: @storage_class
    )
  end

  def generate_object_url
    "https://#{@bucket}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{URI.encode_www_form_component(@file_path)}"
  end
end