require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action allows for integration with AWS S3 for content management and deployment.
#
# It is initialized with an AWS S3 bucket name and a file path. It uploads the file to the S3 bucket
# under the specified key.
#
# Example usage: When you want to upload AI-generated content or backups to AWS S3.

class AwsS3FileUploaderAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(file_path)
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'],
                                     access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                                     secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    upload_file_to_s3
  rescue Aws::S3::Errors::ServiceError => e
    error_message = "Error uploading file to S3: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Unexpected error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def upload_file_to_s3
    @s3_client.put_object(bucket: @bucket_name, key: @s3_key, body: File.read(@file_path))
    Sublayer.configuration.logger.log(:info, "File uploaded successfully to #{@bucket_name}/#{@s3_key}")
  end
end
