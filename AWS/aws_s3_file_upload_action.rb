require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3 buckets.
# This action facilitates archiving and sharing files generated throughout workflows.
#
# It is initialized with a bucket_name, file_path, s3_key, and optionally, region.
# It returns the public URL of the uploaded file as confirmation of a successful upload.
#
# Example usage: When you need to archive workflow outputs to an S3 bucket for persistence.

class AwsS3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key:, region: 'us-east-1')
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key
    @region = region
    @client = Aws::S3::Client.new(region: @region)
  end

  def call
    begin
      upload_to_s3
      public_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_to_s3
    File.open(@file_path, 'rb') do |file|
      @client.put_object(
        bucket: @bucket_name,
        key: @s3_key,
        body: file
      )
    end
    Sublayer.configuration.logger.log(:info, "File uploaded successfully to S3: #{@s3_key}")
  end

  def public_url
    "https://#{@bucket_name}.s3.amazonaws.com/#{@s3_key}"
  end
end
