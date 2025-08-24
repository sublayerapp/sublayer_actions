require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for downloading a file from AWS S3.
# This action allows for integration with AWS S3 to retrieve files for local processing or as input for a Sublayer::Generator.
#
# It is initialized with an S3 bucket, key, and optional local download path.
# It downloads the file to the specified path or to the current directory if no path is provided.
#
# Example usage: When you need to process data stored in S3 using Sublayer's capabilities.

class AwsS3FileDownloaderAction < Sublayer::Actions::Base
  def initialize(bucket:, key:, download_path: nil)
    @bucket = bucket
    @key = key
    @download_path = download_path || File.basename(key)
    @client = Aws::S3::Client.new(region: ENV['AWS_REGION'])
  end

  def call
    download_file_from_s3
  rescue Aws::S3::Errors::ServiceError => e
    error_message = "Error downloading file from S3: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def download_file_from_s3
    @client.get_object(response_target: @download_path, bucket: @bucket, key: @key)
    Sublayer.configuration.logger.log(:info, "Successfully downloaded #{@key} from #{@bucket} to #{@download_path}")
  end
end