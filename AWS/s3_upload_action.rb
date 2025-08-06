require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action provides a simple interface for uploading files or raw content to an S3 bucket.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with:
# - bucket_name: The name of the S3 bucket
# - key: The S3 key (path/filename) where the file should be stored
# - file_path: (Optional) The local path to the file to upload
# - content: (Optional) The raw content to upload if no file_path is provided
# - content_type: (Optional) The MIME type of the content (default: application/octet-stream)
#
# Returns the URL of the uploaded file in S3.
#
# Example usage: When you want to store files (like AI-generated images or large text outputs)
# in S3 for later retrieval or sharing.

class S3UploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, key:, file_path: nil, content: nil, content_type: 'application/octet-stream')
    @bucket_name = bucket_name
    @key = key
    @file_path = file_path
    @content = content
    @content_type = content_type
    
    @client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def call
    raise ArgumentError, 'Either file_path or content must be provided' if @file_path.nil? && @content.nil?
    raise ArgumentError, 'Only one of file_path or content should be provided' if @file_path && @content

    begin
      upload_to_s3
      generate_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_to_s3
    upload_params = {
      bucket: @bucket_name,
      key: @key,
      content_type: @content_type
    }

    if @file_path
      upload_params[:body] = File.open(@file_path, 'rb')
    else
      upload_params[:body] = @content
    end

    @client.put_object(upload_params)
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded to S3: #{@bucket_name}/#{@key}")
  end

  def generate_url
    signer = Aws::S3::Presigner.new(client: @client)
    
    # Generate a URL that expires in 1 hour
    url = signer.presigned_url(
      :get_object,
      bucket: @bucket_name,
      key: @key,
      expires_in: 3600
    )
    
    Sublayer.configuration.logger.log(:info, "Generated presigned URL for S3 object")
    url
  end
end