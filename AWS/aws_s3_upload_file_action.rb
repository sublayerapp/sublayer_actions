require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading a file to an AWS S3 bucket.
# This action simplifies the process of uploading files which can be useful for sharing and storage
# of LLM-generated files or outputs.
#
# It is initialized with bucket_name, file_path, and optionally, key.
# It returns the public URL of the uploaded file once completed successfully.
#
# Example usage: When you have generated files that need to be uploaded to cloud storage for accessibility.

class AWSS3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, key: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @key = key || File.basename(file_path)
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'])
  end

  def call
    begin
      upload_file_to_s3
      public_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file_to_s3
    File.open(@file_path, 'rb') do |file|
      @s3_client.put_object(bucket: @bucket_name, key: @key, body: file)
    end
    Sublayer.configuration.logger.log(:info, "File uploaded to S3 bucket #{@bucket_name} with key #{@key}")
  end

  def public_url
    "https://#{@bucket_name}.s3.amazonaws.com/#{@key}"
  end
end