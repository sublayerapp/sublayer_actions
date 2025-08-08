require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# This action enables easy integration with S3 storage for files generated in AI workflows,
# such as reports, images, or data exports.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with bucket_name, file_key (the path/name in S3), and file_content.
# Optional parameters include content_type, metadata, and acl.
# It returns the S3 object URL on successful upload.
#
# Example usage: When you want to store AI-generated content (like reports or images)
# in S3 for later access or distribution.

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, file_key:, file_content:, content_type: nil, metadata: {}, acl: 'private')
    @bucket_name = bucket_name
    @file_key = file_key
    @file_content = file_content
    @content_type = content_type
    @metadata = metadata
    @acl = acl
    @client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def call
    begin
      upload_params = {
        bucket: @bucket_name,
        key: @file_key,
        body: @file_content,
        acl: @acl,
        metadata: @metadata
      }

      # Add content_type if specified
      upload_params[:content_type] = @content_type if @content_type

      # Perform the upload
      response = @client.put_object(upload_params)

      # Generate the object URL
      object_url = "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@file_key}"
      
      Sublayer.configuration.logger.log(:info, "Successfully uploaded file to S3: #{object_url}")
      
      object_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "AWS S3 service error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error uploading file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end