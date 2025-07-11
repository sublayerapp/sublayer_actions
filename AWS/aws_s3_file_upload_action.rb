require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action allows integration with AWS S3, a scalable cloud storage service.
# It can be used to store AI-generated outputs, logs, or any files needed in the cloud.
#
# It is initialized with the bucket_name, file_path, and optional s3_key (desired name in S3 bucket).
# Returns the public URL of the uploaded file in S3.
#
# Example usage: When you want to save AI-generated data or logs to an AWS S3 bucket for persistent storage and sharing.

class AWSS3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(file_path)
    @client = Aws::S3::Client.new(region: ENV['AWS_REGION'],
                                  access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                                  secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    upload_file
  rescue Aws::Errors::ServiceError => e
    error_message = "Error uploading file to S3: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def upload_file
    File.open(@file_path, 'rb') do |file|
      @client.put_object(bucket: @bucket_name, key: @s3_key, body: file)
    end

    public_url = "https://#{@bucket_name}.s3.amazonaws.com/#{@s3_key}"
    Sublayer.configuration.logger.log(:info, "File uploaded successfully to S3: #{public_url}")
    public_url
  end
end
