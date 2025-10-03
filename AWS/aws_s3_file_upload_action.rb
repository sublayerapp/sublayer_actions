require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading a file to a specified AWS S3 bucket.
# This action is typically used to store outputs from Sublayer workflows, such as generating content or backups
# from AI processes.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a bucket_name, file_path, and s3_key (the key under which the file is stored in S3).
#
# Example usage: When you want to save LLM-generated data to an AWS S3 bucket for later access or backup.

class AwsS3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key:, region: 'us-east-1')
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key
    @region = region
    @s3_client = Aws::S3::Client.new(region: @region)
  end

  def call
    begin
      upload_file_to_s3
      Sublayer.configuration.logger.log(:info, "Successfully uploaded file to '#{@bucket_name}/#{@s3_key}'")
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file_to_s3
    File.open(@file_path, 'rb') do |file|
      @s3_client.put_object(bucket: @bucket_name, key: @s3_key, body: file)
    end
  end
end
