require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading a file to an Amazon S3 bucket.
# This action is intended to be used for storing outputs from Sublayer tasks that require persistent storage
# or sharing results with other cloud services.
#
# It is initialized with a bucket_name, file_path, and object_key (the name in the bucket).
# It returns the URL of the uploaded file as confirmation of success.
#
# Example usage: When you need to store a log file or result from a Sublayer workflow to your S3 bucket.

class AwsS3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, object_key:)
    @bucket_name = bucket_name
    @file_path = file_path
    @object_key = object_key
    @client = Aws::S3::Client.new(region: ENV['AWS_REGION'])
  end

  def call
    upload_file_to_s3
  rescue Aws::S3::Errors::ServiceError => e
    handle_error("AWS S3 error during file upload: #{e.message}")
  rescue StandardError => e
    handle_error("General error during file upload: #{e.message}")
  end

  private

  def upload_file_to_s3
    File.open(@file_path, 'rb') do |file|
      @client.put_object(bucket: @bucket_name, key: @object_key, body: file)
      result_url = "https://#{@bucket_name}.s3.amazonaws.com/#{@object_key}"
      Sublayer.configuration.logger.log(:info, "File uploaded to AWS S3 successfully: #{result_url}")
      return result_url
    end
  end
  
  def handle_error(message)
    Sublayer.configuration.logger.log(:error, message)
    raise StandardError, message
  end
end
