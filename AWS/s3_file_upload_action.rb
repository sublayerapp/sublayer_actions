require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3 buckets.
# This action allows for easy integration with AWS S3 storage in AI workflows,
# particularly useful for persisting generated files like images or documents.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with the file content, bucket name, and key for the S3 object.
# It returns the URL of the uploaded file on successful upload.
#
# Example usage: When you want to store AI-generated files (like from OpenAIImageGenerationAction)
# in S3 for persistent storage and access.

class S3FileUploadAction < Sublayer::Actions::Base
  def initialize(file_content:, bucket:, key:, content_type: nil, acl: 'private')
    @file_content = file_content
    @bucket = bucket
    @key = key
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
      upload_file
      generate_url
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
    params = {
      bucket: @bucket,
      key: @key,
      body: @file_content,
      acl: @acl
    }
    
    # Add content_type if specified
    params[:content_type] = @content_type if @content_type

    @client.put_object(params)
    
    Sublayer.configuration.logger.log(:info, "Successfully uploaded file to S3: #{@bucket}/#{@key}")
  end

  def generate_url
    if @acl == 'public-read'
      "https://#{@bucket}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@key}"
    else
      presigned_url = @client.generate_presigned_url(
        'get_object',
        bucket: @bucket,
        key: @key,
        expires_in: 3600 # URL expires in 1 hour
      )
      Sublayer.configuration.logger.log(:info, "Generated presigned URL for private S3 object")
      presigned_url
    end
  end
end