require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for downloading files from a specified AWS S3 bucket.
# This action allows for integration with S3, enabling data retrieval for AI workflow processing.
#
# It is initialized with a bucket_name and object_key, and downloads the specified file to a local path.
#
# Example usage: When you need to process data stored in S3 within a Sublayer workflow.

class AWSS3DownloadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, object_key:, download_path:)
    @bucket_name = bucket_name
    @object_key = object_key
    @download_path = download_path
    @client = Aws::S3::Client.new(region: ENV['AWS_REGION'])
  end

  def call
    begin
      download_file
      Sublayer.configuration.logger.log(:info, "File downloaded successfully from S3 bucket '#{@bucket_name}' with key '#{@object_key}'")
    rescue Aws::Errors::ServiceError => e
      error_message = "Error downloading file from S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def download_file
    @client.get_object(response_target: @download_path, bucket: @bucket_name, key: @object_key)
  end
end
