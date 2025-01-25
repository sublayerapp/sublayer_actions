require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action facilitates the integration of AI-generated content with cloud storage.
#
# It is initialized with the bucket name, file path, and object key for S3.
# Example usage: When you want to store AI-generated outputs to S3 to be accessed later or by other services.

class AWSFileUploadAction < Sublayer::Actions::Base
  def initialize(bucket:, file_path:, object_key:)
    @bucket = bucket
    @file_path = file_path
    @object_key = object_key
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'],
                                     access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                                     secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    begin
      upload_file
      Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to #{@bucket}/#{@object_key}")
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    File.open(@file_path, 'rb') do |file|
      @s3_client.put_object(bucket: @bucket, key: @object_key, body: file)
    end
  end
end
