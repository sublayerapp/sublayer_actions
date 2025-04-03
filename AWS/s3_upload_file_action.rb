require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to Amazon S3.
# This action enables easy integration with AWS S3 storage for storing AI-generated content,
# backups, or any other data that needs to be persisted in cloud storage.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a bucket_name, file_path (the destination path in S3),
# and file_content (the data to upload).
# It returns the URL of the uploaded file in S3.
#
# Example usage: When you want to store AI-generated assets, backups, or processed
# data in Amazon S3 cloud storage.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, file_content:)
    @bucket_name = bucket_name
    @file_path = file_path
    @file_content = file_content
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
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error during S3 upload: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def upload_to_s3
    @client.put_object(
      bucket: @bucket_name,
      key: @file_path,
      body: @file_content
    )
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded file to S3: #{@file_path}")
  end

  def generate_file_url
    "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{URI.encode_www_form_component(@file_path)}"
  end
end