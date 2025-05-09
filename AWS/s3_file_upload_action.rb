# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This is useful for cloud storage solutions where files generated during workflows need to be stored or shared.
#
# It is initialized with a bucket_name, file_path, and optional key (S3 object key).
# It returns the public URL of the uploaded file if successful.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# Example usage: When you want to store files generated from an AI process to an S3 bucket for cloud storage or sharing.

require 'aws-sdk-s3'

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, key: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @key = key || File.basename(file_path)
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'])
  end

  def call
    upload_file
    generate_public_url
  end

  private

  def upload_file
    begin
      @s3_client.put_object(bucket: @bucket_name, key: @key, body: File.read(@file_path))
      Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to #{@bucket_name}/#{@key}")
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def generate_public_url
    Aws::S3::Object.new(@s3_client, bucket_name: @bucket_name, key: @key).public_url
  end
end
