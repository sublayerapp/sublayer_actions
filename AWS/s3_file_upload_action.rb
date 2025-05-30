require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action is useful for storing generated files or backups in cloud storage.
#
# It is initialized with a bucket_name, file_path, and optional s3_key for the file on S3.
# It returns the public URL of the uploaded file.
#
# Example usage: Use this action to upload AI-generated reports or data backups to an S3 bucket for persisting or sharing.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(file_path)
    @s3_client = Aws::S3::Client.new(region: ENV['AWS_REGION'], access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    begin
      upload_file
      Sublayer.configuration.logger.log(:info, "File successfully uploaded to #{@bucket_name}/#{@s3_key}")
      object_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error during S3 upload: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def upload_file
    File.open(@file_path, 'rb') do |file|
      @s3_client.put_object(bucket: @bucket_name, key: @s3_key, body: file)
    end
  end

  def object_url
    "https://#{ENV['AWS_REGION']}.amazonaws.com/#{@bucket_name}/#{@s3_key}"
  end
end
