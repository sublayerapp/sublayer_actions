require 'aws-sdk-s3'

# Description: This Sublayer::Action is responsible for uploading files to an Amazon S3 bucket.
# It allows seamless integration with AWS S3 for storing AI-generated outputs like reports, images, or logs.
#
# It is initialized with a file_path, bucket_name, and optional AWS credentials (access_key_id and secret_access_key).
# It uploads the file to the specified S3 bucket and returns the public URL of the uploaded file for confirmation.
#
# Example usage: When you want to save AI-generated logs or images to an S3 bucket for persistent storage or sharing.

class AmazonS3UploadAction < Sublayer::Actions::Base
  def initialize(file_path:, bucket_name:, access_key_id: nil, secret_access_key: nil)
    @file_path = file_path
    @bucket_name = bucket_name
    @access_key_id = access_key_id || ENV['AWS_ACCESS_KEY_ID']
    @secret_access_key = secret_access_key || ENV['AWS_SECRET_ACCESS_KEY']
    @s3_client = Aws::S3::Client.new(
      access_key_id: @access_key_id,
      secret_access_key: @secret_access_key,
      region: 'us-east-1' # You may want to make this configurable
    )
  end

  def call
    begin
      upload_file
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    else
      Sublayer.configuration.logger.log(:info, "File uploaded successfully to #{@bucket_name}")
      public_url
    end
  end

  private

  def upload_file
    File.open(@file_path, 'rb') do |file|
      @s3_client.put_object(bucket: @bucket_name, key: File.basename(@file_path), body: file)
    end
  end

  def public_url
    "https://#{@bucket_name}.s3.amazonaws.com/#{File.basename(@file_path)}"
  end
end