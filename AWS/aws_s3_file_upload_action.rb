require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action allows easy integration with AWS S3 storage, which can be useful for
# storing AI-generated documents, images, or data files in cloud storage for further
# processing or distribution.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a bucket name, file path, and optional parameters for S3 object key and ACL.
# It returns the S3 object's public URL if the upload is successful.
#
# Example usage: When you want to store AI-generated content or processed data in AWS S3.

class AwsS3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, object_key: nil, acl: 'private')
    @bucket_name = bucket_name
    @file_path = file_path
    @object_key = object_key || File.basename(@file_path)
    @acl = acl
    @client = Aws::S3::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def call
    begin
      File.open(@file_path, 'rb') do |file|
        response = @client.put_object(
          bucket: @bucket_name,
          key: @object_key,
          body: file,
          acl: @acl
        )
        
        if response.etag
          public_url = "https://#{@bucket_name}.s3.amazonaws.com/#{@object_key}"
          Sublayer.configuration.logger.log(:info, "File successfully uploaded to S3: #{public_url}")
          return public_url
        else
          raise StandardError, "File upload to S3 failed"
        end
      end
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end