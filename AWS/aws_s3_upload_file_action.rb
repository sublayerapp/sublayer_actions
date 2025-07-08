require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading a file to an AWS S3 bucket.
# This action is ideal for storing large outputs or datasets for further processing or sharing.
#
# It is initialized with a bucket name, file path (on the local filesystem), and the destination key (in S3).
# It returns the public URL of the uploaded file for access.
#
# Example usage: When you need to save AI-generated data to an S3 bucket for further analysis or sharing.

class AwsS3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, destination_key:)
    @bucket_name = bucket_name
    @file_path = file_path
    @destination_key = destination_key
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'],
                                     access_key_id: ENV['AWS_ACCESS_KEY_ID'],
                                     secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    begin
      upload_file
      file_url = "https://#{@bucket_name}.s3.amazonaws.com/#{@destination_key}"
      Sublayer.configuration.logger.log(:info, "File uploaded successfully to S3 with URL: \\#{file_url}")
      file_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    File.open(@file_path, 'rb') do |file|
      @s3_client.put_object(bucket: @bucket_name, key: @destination_key, body: file)
    end
  end
end
