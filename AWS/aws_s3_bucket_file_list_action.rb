require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for retrieving and listing files in a specified AWS S3 bucket.
# This can be used for tasks like backups or generating input for Generators.
#
# It is initialized with a bucket_name and optionally a prefix to filter files.
# It returns an array of file keys in the specified bucket.
#
# Example usage: When you need to list all the files in an S3 bucket to use as input for another action.

class AwsS3BucketFileListAction < Sublayer::Actions::Base
  def initialize(bucket_name:, prefix: '')
    @bucket_name = bucket_name
    @prefix = prefix
    @client = Aws::S3::Client.new
  end

  def call
    list_files
  rescue Aws::S3::Errors::ServiceError => e
    error_message = "Error listing files in bucket #{@bucket_name}: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def list_files
    response = @client.list_objects_v2(bucket: @bucket_name, prefix: @prefix)
    file_keys = response.contents.map(&:key)
    Sublayer.configuration.logger.log(:info, "Successfully retrieved #{file_keys.size} files from S3 bucket #{@bucket_name}")
    file_keys
  end
end