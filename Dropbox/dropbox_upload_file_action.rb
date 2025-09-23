require 'dropbox_api'

# Description: Sublayer::Action responsible for uploading a file to Dropbox.
# This action facilitates easy storage of generated outputs or backups in cloud storage.
#
# It is initialized with a file_path (local path to the file) and a dropbox_path (the path in Dropbox where the file should be uploaded).
# It returns the metadata of the uploaded file confirming successful upload.
#
# Example usage: When you need to upload generated reports, backups, or any output files to Dropbox for persistent storage.

class DropboxUploadFileAction < Sublayer::Actions::Base
  def initialize(file_path:, dropbox_path:)
    @file_path = file_path
    @dropbox_path = dropbox_path
    @client = DropboxApi::Client.new(ENV['DROPBOX_OAUTH_TOKEN'])
  end

  def call
    upload_file
  rescue DropboxApi::Errors::HttpError => e
    error_message = "HTTP error during Dropbox upload: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error uploading file to Dropbox: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def upload_file
    File.open(@file_path, 'r') do |file|
      metadata = @client.upload(@dropbox_path, file.read)
      Sublayer.configuration.logger.log(:info, "File uploaded successfully to Dropbox at '#{@dropbox_path}'")
      metadata
    end
  end
end
