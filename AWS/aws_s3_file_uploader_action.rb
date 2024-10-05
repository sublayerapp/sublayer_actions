# Description: Sublayer::Action responsible for uploading files to an Amazon S3 bucket.
# This integrates cloud storage solutions into workflows, making it ideal for handling generated data or backups.
#
# It is initialized with bucket_name, file_path, and key. It returns the public URL of the uploaded file to confirm successful upload.
#
# Example usage: When you have a file generated as part of a process and you want to store it in AWS S3 for long-term storage or further processing.

require 'aws-sdk-s3'

class AwsS3FileUploaderAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, key:, **options)
    @bucket_name = bucket_name
    @file_path = file_path
    @key = key
    @options = options
    @s3_client = Aws::S3::Client.new(region: options[:region] || 'us-east-1')
  end

  def call
    upload_file_to_s3
  end

  private

  def upload_file_to_s3
    begin
      @s3_client.put_object(bucket: @bucket_name, key: @key, body: File.read(@file_path))
      public_url
    rescue Aws::S3::Errors::ServiceError => e
      Sublayer.configuration.logger.log(:error, "Error uploading file to S3: #{e.message}")
      raise e
    end
  end

  def public_url
    "https://#{@bucket_name}.s3.amazonaws.com/#{@key}"
  end
end
