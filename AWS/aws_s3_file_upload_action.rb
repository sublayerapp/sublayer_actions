require 'aws-sdk-s3'

# Description: Sublayer::Action responsible for uploading files to AWS S3.
# It is initialized with a file_path, bucket_name, and optional metadata.
# Returns a success message with the file URL.
#
# Example usage: When you need to upload generated files or data to S3 for storage or sharing purposes.

class AWSS3FileUploadAction < Sublayer::Actions::Base
  def initialize(file_path:, bucket_name:, metadata: {})
    @file_path = file_path
    @bucket_name = bucket_name
    @metadata = metadata
    @client = Aws::S3::Client.new(region: ENV['AWS_REGION'], access_key_id: ENV['AWS_ACCESS_KEY_ID'], secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'])
  end

  def call
    begin
      file_name = File.basename(@file_path)
      obj = @client.put_object({
        bucket: @bucket_name,
        key: file_name,
        body: File.open(@file_path),
        metadata: @metadata
      })

      file_url = "https://#{@bucket_name}.s3.amazonaws.com/#{file_name}"
      Sublayer.configuration.logger.log(:info, "File uploaded successfully to #{file_url}")
      { success: true, file_url: file_url }
    rescue Aws::S3::Errors::ServiceError => e
      error_message = "Failed to upload file to S3: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end