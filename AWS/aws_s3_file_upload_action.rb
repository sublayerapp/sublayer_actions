require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action facilitates storage of generated content or logs directly from Sublayer workflows,
# enabling scalable and reliable cloud storage solutions.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a bucket_name, file_path, and optionally an object_key.
# The file is read from the specified file_path and uploaded to the specified S3 bucket.
#
# Example usage: When you want to upload a log file or generated content
# to a specific S3 bucket as part of an AI-driven workflow.

class AWSS3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, object_key: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @object_key = object_key || File.basename(file_path)
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'],
                                     access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                                     secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    begin
      upload_file
      Sublayer.configuration.logger.log(:info, "File successfully uploaded to S3 bucket '#{@bucket_name}' as '#{@object_key}'")
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    File.open(@file_path, 'rb') do |file|
      @s3_client.put_object(bucket: @bucket_name, key: @object_key, body: file)
    end
  end
end
