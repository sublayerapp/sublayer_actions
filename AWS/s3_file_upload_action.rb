require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This allows for easy storage of AI-generated data or assets in a scalable manner.
#
# Requires: aws-sdk-s3 gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile.
#
# It is initialized with bucket_name, file_path, and object_key (the key under which the file will be stored in S3).
# It returns the public URL of the uploaded file.
#
# Example usage: When you need to store LLM-generated files or data into persistent storage.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, object_key:, region: 'us-east-1')
    @bucket_name = bucket_name
    @file_path = file_path
    @object_key = object_key
    @region = region
    @client = Aws::S3::Client.new(region: @region)
  end

  def call
    begin
      upload_file
      file_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    @client.put_object(bucket: @bucket_name, key: @object_key, body: File.read(@file_path))
    Sublayer.configuration.logger.log(:info, "File successfully uploaded to S3 bucket #{@bucket_name} under key #{@object_key}")
  end

  def file_url
    "https://#{@bucket_name}.s3.amazonaws.com/#{@object_key}"
  end
end
