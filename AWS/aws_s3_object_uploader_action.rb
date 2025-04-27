require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action allows for storing files in a scalable cloud environment, suitable for AI-generated outputs.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a bucket_name, file_path, and key.
# On successful execution, it uploads the file to the specified S3 bucket and returns the object's URL.
#
# Example usage: When you want to save AI-generated images or data files to an S3 bucket.

class AwsS3ObjectUploaderAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, key:, region: 'us-east-1')
    @bucket_name = bucket_name
    @file_path = file_path
    @key = key
    @s3_client = Aws::S3::Client.new(region: region, access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    begin
      upload_file
      object_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    File.open(@file_path, 'rb') do |file|
      @s3_client.put_object(bucket: @bucket_name, key: @key, body: file)
      Sublayer.configuration.logger.log(:info, "File #{@file_path} uploaded successfully to #{@bucket_name}/#{@key}")
    end
  end

  def object_url
    "https://#{@bucket_name}.s3.amazonaws.com/#{@key}"
  end
end