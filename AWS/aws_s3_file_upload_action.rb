require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading a file to a specified AWS S3 bucket.
# This action allows for easy integration with AWS S3 storage within Sublayer workflows.
#
# It is initialized with the bucket name, file name, and file content.
# It returns the response from the S3 upload operation (AWS::S3::Types::PutObjectOutput).
#
# Example usage: When you want to store files generated by your Sublayer workflow in an S3 bucket.

class AwsS3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_name:, file_content:)
    @bucket_name = bucket_name
    @file_name = file_name
    @file_content = file_content
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'] || 'us-east-1')
  end

  def call
    begin
      response = @s3_client.put_object(
        bucket: @bucket_name,
        key: @file_name,
        body: @file_content
      )

      Sublayer.configuration.logger.log(:info, "File '#{@file_name}' uploaded to bucket '#{@bucket_name}' successfully.")

      response
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end