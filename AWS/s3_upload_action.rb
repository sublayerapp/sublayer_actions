require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading content to an AWS S3 bucket.
# This action enables storing files or string content in S3, which is useful for
# persisting LLM-generated content, analysis results, or archiving data.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with a bucket_name, object_key, and either file_path or content.
# On successful execution, it returns the S3 object URL.
#
# Example usage: When you want to persist LLM-generated content or analysis results
# to S3 for later retrieval or sharing.

class S3UploadAction < Sublayer::Actions::Base
  def initialize(bucket_name:, object_key:, file_path: nil, content: nil)
    @bucket_name = bucket_name
    @object_key = object_key
    @file_path = file_path
    @content = content
    
    if @file_path.nil? && @content.nil?
      raise ArgumentError, 'Either file_path or content must be provided'
    end
    
    if @file_path && @content
      raise ArgumentError, 'Only one of file_path or content should be provided'
    end
    
    @client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def call
    begin
      upload_to_s3
      object_url = generate_object_url
      Sublayer.configuration.logger.log(:info, "Successfully uploaded to S3: #{object_url}")
      object_url
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "AWS S3 error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error uploading to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def upload_to_s3
    if @file_path
      upload_file
    else
      upload_content
    end
  end

  def upload_file
    File.open(@file_path, 'rb') do |file|
      @client.put_object(
        bucket: @bucket_name,
        key: @object_key,
        body: file
      )
    end
  end

  def upload_content
    @client.put_object(
      bucket: @bucket_name,
      key: @object_key,
      body: @content
    )
  end

  def generate_object_url
    "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@object_key}"
  end
end