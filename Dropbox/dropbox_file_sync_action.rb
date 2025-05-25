# Description: Sublayer::Action responsible for synchronizing a local directory with a Dropbox folder.
# This action uploads and backs up all changes to Dropbox, ensuring data is consistently stored in the cloud.
#
# It is initialized with a local_path and dropbox_folder_path.
# Any discrepancies between the local directory and the Dropbox folder will trigger uploads to Dropbox.
#
# Example usage: Use this action to automatically back up local files to Dropbox in a Sublayer workflow.

require 'dropbox_api'

class DropboxFileSyncAction < Sublayer::Actions::Base
  def initialize(local_path:, dropbox_folder_path:, **kwargs)
    super(**kwargs)
    @local_path = local_path
    @dropbox_folder_path = dropbox_folder_path
    @client = DropboxApi::Client.new(ENV['DROPBOX_OAUTH_BEARER'])
  end

  def call
    begin
      sync_directory(@local_path, @dropbox_folder_path)
      Sublayer.configuration.logger.log(:info, "Successfully synchronized directory #{@local_path} with Dropbox folder #{@dropbox_folder_path}")
    rescue DropboxApi::Errors::HttpError => e
      error_message = "Dropbox HTTP error during file sync: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during Dropbox file sync: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def sync_directory(local_path, dropbox_folder_path)
    Dir.glob(File.join(local_path, '**', '*')).each do |file|
      next if File.directory?(file)
      dropbox_path = File.join(dropbox_folder_path, file.sub(local_path, ''))
      upload_file(file, dropbox_path)
    end
  end

  def upload_file(local_file, dropbox_path)
    content = File.read(local_file)
    @client.upload(dropbox_path, content, mode: :overwrite)
  end
end