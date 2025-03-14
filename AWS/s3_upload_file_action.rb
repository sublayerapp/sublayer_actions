require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to Amazon S3.
# This action enables easy integration with AWS S3 storage for storing AI-generated content,
# backups, or processed files in cloud storage.
#
# Requires: 'aws-sdk-s3' gem
# $ gem install aws-sdk-s3
# Or add `gem 'aws-sdk-s3'` to your Gemfile
#
# It is initialized with bucket_name, s3_key (destination path), and either file_path or content.
# It returns the S3 object URL of the uploaded file.
#
# Example usage: When you want to store AI-generated content, backups, or processed files in S3.
# This could be useful for:
# - Storing generated documents
# - Backing up analysis results
# - Archiving processed data
# - Creating cloud-accessible assets

class S3UploadFileAction < Sublayer::Actions::Base
  def initialize(bucket_name:, s3_key:, file_path: nil, content: nil, content_type: nil)
    @bucket_name = bucket_name
    @s3_key = s3_key
    @file_path = file_path
    @content = content
    @content_type = content_type
    
    if @file_path.nil? && @content.nil?
      raise ArgumentError, 'Either file_path or content must be provided'
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
    upload_params = {
      bucket: @bucket_name,
      key: @s3_key
    }

    if @file_path
      upload_params[:body] = File.open(@file_path, 'rb')
      upload_params[:content_type] = @content_type || get_content_type_from_file
    else
      upload_params[:body] = @content
      upload_params[:content_type] = @content_type if @content_type
    end

    @client.put_object(upload_params)
  end

  def generate_object_url
    "https://#{@bucket_name}.s3.#{ENV['AWS_REGION']}.amazonaws.com/#{@s3_key}"
  end

  def get_content_type_from_file
    return nil unless @file_path
    
    case File.extname(@file_path).downcase
    when '.txt'
      'text/plain'
    when '.html'
      'text/html'
    when '.json'
      'application/json'
    when '.pdf'
      'application/pdf'
    when '.png'
      'image/png'
    when '.jpg', '.jpeg'
      'image/jpeg'
    else
      'application/octet-stream'
    end
  end
end