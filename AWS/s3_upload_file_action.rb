require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action facilitates storing AI-generated assets, backups, or large files that result from AI processing.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a bucket_name, file source (either local path or content), and destination path in S3.
# It returns the S3 object URL of the uploaded file.
#
# Example usage: When you want to store AI-generated files, such as images, documents, or data files in S3.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, destination_path:, file_path: nil, file_content: nil)
    @bucket_name = bucket_name
    @destination_path = destination_path
    @file_path = file_path
    @file_content = file_content

    raise ArgumentError, 'Either file_path or file_content must be provided' if file_path.nil? && file_content.nil?
    raise ArgumentError, 'Only one of file_path or file_content should be provided' if file_path && file_content

    @client = Aws::S3::Client.new(
      region: ENV['AWS_REGION'] || 'us-east-1',
      credentials: Aws::Credentials.new(
        ENV['AWS_ACCESS_KEY_ID'],
        ENV['AWS_SECRET_ACCESS_KEY']
      )
    )
  end

  def call
    begin
      upload_file
      generate_object_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "S3 service error during upload: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def upload_file
    if @file_path
      upload_from_file
    else
      upload_from_content
    end

    Sublayer.configuration.logger.log(:info, "Successfully uploaded to S3: #{@destination_path}")
  end

  def upload_from_file
    File.open(@file_path, 'rb') do |file|
      @client.put_object(
        bucket: @bucket_name,
        key: @destination_path,
        body: file
      )
    end
  end

  def upload_from_content
    @client.put_object(
      bucket: @bucket_name,
      key: @destination_path,
      body: @file_content
    )
  end

  def generate_object_url
    "https://#{@bucket_name}.s3.#{@client.config.region}.amazonaws.com/#{@destination_path}"
  end
end