require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to an AWS S3 bucket.
# This action enables cloud storage integration within Sublayer workflows, particularly
# useful for storing AI-generated content like images, documents, or other files.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with file_content, bucket_name, and file_path parameters.
# It returns the URL of the uploaded file on successful upload.
#
# Example usage: When you want to store AI-generated files (like DALL-E images,
# generated documents, etc.) in cloud storage for distribution or persistence.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(file_content:, bucket_name:, file_path:, content_type: nil, acl: 'private')
    @file_content = file_content
    @bucket_name = bucket_name
    @file_path = file_path
    @content_type = content_type
    @acl = acl
    @client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def call
    begin
      upload_to_s3
      generate_file_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Error uploading to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error during S3 upload: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def upload_to_s3
    params = {
      bucket: @bucket_name,
      key: @file_path,
      body: @file_content,
      acl: @acl
    }
    
    # Add content_type if specified
    params[:content_type] = @content_type if @content_type

    @client.put_object(params)
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded file to S3: #{@file_path}")
  end

  def generate_file_url
    if @acl == 'public-read'
      "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@file_path}"
    else
      # Generate a presigned URL for private files that expires in 1 hour
      signer = Aws::S3::Presigner.new(client: @client)
      signer.presigned_url(
        :get_object,
        bucket: @bucket_name,
        key: @file_path,
        expires_in: 3600
      )
    end
  end
end