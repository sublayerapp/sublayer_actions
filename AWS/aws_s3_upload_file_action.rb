require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action allows for easy integration with AWS S3 for file storage and retrieval.
#
# It is initialized with a bucket name and file path, and it uploads the specified file to the bucket.
#
# Example usage: When you want to save files generated from AI-driven processes into AWS S3 for persistence or sharing.

class AwsS3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(file_path)
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'],
                                     access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                                     secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    begin
      upload_file
      Sublayer.configuration.logger.log(:info, "File uploaded to S3 bucket '\#{@bucket_name}' with key '\#{@s3_key}'")
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    @s3_client.put_object(bucket: @bucket_name,
                          key: @s3_key,
                          body: File.open(@file_path, 'rb'))
  end
end
