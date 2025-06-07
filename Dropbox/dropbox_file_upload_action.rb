require 'dropbox_api'

# Description: Sublayer::Action responsible for uploading a file to a specified folder in Dropbox.
# This action can be integrated into workflows where data generated or compiled
# needs to be stored and shared in a centralized cloud location.
#
# It is initialized with a folder_path, file_name, and file_contents.
# On successful execution, it uploads the file to Dropbox and returns the metadata of the uploaded file.
#
# Example usage: When you want to store a report generated from AI analytics to Dropbox for team access.

class DropboxFileUploadAction < Sublayer::Actions::Base
  def initialize(folder_path:, file_name:, file_contents:)
    @folder_path = folder_path
    @file_name = file_name
    @file_contents = file_contents
    @client = DropboxApi::Client.new(ENV['DROPBOX_OAUTH_BEARER'])
  end

  def call
    begin
      upload_file
      Sublayer.configuration.logger.log(:info, "File uploaded successfully to Dropbox at #{@folder_path}/#{@file_name}")
    rescue DropboxApi::Errors::HttpError => e
      error_message = "HTTP error during Dropbox file upload: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error uploading file to Dropbox: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def upload_file
    @client.upload(File.join(@folder_path, @file_name), @file_contents)
  end
end
