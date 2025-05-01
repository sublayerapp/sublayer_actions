require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action is intended to be used for backing up data or sharing generated outputs in a
# scalable and reliable manner.
#
# It is initialized with a bucket_name, file_path, and s3_key.
# It returns the public URL of the uploaded file to confirm the upload was successful.
#
# Example usage: When you want to backup important data to S3 or share generated
# files via a public URL.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key:)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key
    @client = Aws::S3::Client.new
  end

  def call
    begin
      upload_file
      url = object_url
      Sublayer.configuration.logger.log(:info, "File uploaded successfully to S3: \
      URL: \
{url}")
      url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: \
{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    @client.put_object(
      bucket: @bucket_name,
      key: @s3_key,
      body: File.open(@file_path, 'rb')
    )
  end

  def object_url
    "https://\#{@bucket_name}.s3.amazonaws.com/\#{@s3_key}"
  end
end
