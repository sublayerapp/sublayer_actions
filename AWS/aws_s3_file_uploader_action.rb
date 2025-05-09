require 'aws-sdk-s3'

# Description: Sublayer::Action for uploading files to AWS S3.
# This action allows easy upload of files to a specified S3 bucket, with configurable access levels.
# It is initialized with a bucket name, file path, and access level (such as 'private', 'public-read').
# It returns the S3 object URL upon successful upload.
#
# Example usage: Use this action to upload generated reports or files from AI processes to a cloud storage, enabling further accessibility and sharing.

class AWSS3FileUploaderAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, access_level: 'private')
    @bucket_name = bucket_name
    @file_path = file_path
    @access_level = access_level
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'])
  end

  def call
    begin
      file_name = File.basename(@file_path)
      @s3_client.put_object(
        bucket: @bucket_name,
        key: file_name,
        body: File.read(@file_path),
        acl: @access_level
      )

      object_url = "https://#{@bucket_name}.s3.amazonaws.com/#{file_name}"
      Sublayer.configuration.logger.log(:info, "File uploaded successfully to S3: #{object_url}")
      object_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Unexpected error: #{e.message}")
      raise e
    end
  end
end
