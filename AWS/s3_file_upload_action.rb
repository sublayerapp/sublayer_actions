require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to Amazon S3 buckets.
# This action enables easy integration with AWS S3 storage for workflows that generate files
# that need to be stored and served from cloud storage.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a bucket_name, file_path, and optional parameters for S3 storage configuration.
# It returns the URL of the uploaded file on successful upload.
#
# Example usage: When you want to upload AI-generated files (PDFs, images, audio) to S3 for storage and distribution.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_path:, s3_key: nil, acl: 'private', content_type: nil)
    @bucket_name = bucket_name
    @file_path = file_path
    @s3_key = s3_key || File.basename(file_path)
    @acl = acl
    @content_type = content_type || determine_content_type
    
    @client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def call
    begin
      upload_file
      generate_url
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
    File.open(@file_path, 'rb') do |file|
      @client.put_object(
        bucket: @bucket_name,
        key: @s3_key,
        body: file,
        acl: @acl,
        content_type: @content_type
      )
    end
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded #{@file_path} to S3 bucket #{@bucket_name} with key #{@s3_key}")
  end

  def generate_url
    if @acl == 'public-read'
      "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@s3_key}"
    else
      signer = Aws::S3::Presigner.new(client: @client)
      url = signer.presigned_url(
        :get_object,
        bucket: @bucket_name,
        key: @s3_key,
        expires_in: 3600 # URL expires in 1 hour
      )
      Sublayer.configuration.logger.log(:info, "Generated presigned URL for #{@s3_key}")
      url
    end
  end

  def determine_content_type
    case File.extname(@file_path).downcase
    when '.pdf'
      'application/pdf'
    when '.jpg', '.jpeg'
      'image/jpeg'
    when '.png'
      'image/png'
    when '.gif'
      'image/gif'
    when '.mp3'
      'audio/mpeg'
    when '.mp4'
      'video/mp4'
    when '.json'
      'application/json'
    when '.txt'
      'text/plain'
    else
      'application/octet-stream'
    end
  end
end