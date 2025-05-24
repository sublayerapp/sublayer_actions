require 'dropbox_sdk'

# Description: Sublayer::Action responsible for backing up specific files or folders to Dropbox.
# Automates the backup process at scheduled intervals, ensuring essential data is always secure.
#
# Example usage: When you want to ensure critical project files are backed up to Dropbox to prevent data loss.

class DropboxFileBackupAction < Sublayer::Actions::Base
  def initialize(access_token:, source_path:, dropbox_path:)
    @access_token = access_token
    @source_path = source_path
    @dropbox_path = dropbox_path
    @client = DropboxClient.new(@access_token)
  end

  def call
    begin
      upload_to_dropbox
      Sublayer.configuration.logger.log(:info, "Successfully backed up #{@source_path} to Dropbox at #{@dropbox_path}")
    rescue DropboxError => e
      error_message = "Error during Dropbox backup: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error during Dropbox backup: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def upload_to_dropbox
    if File.directory?(@source_path)
      Dir.glob(File.join(@source_path, '**', '*')).each do |file|
        next if File.directory?(file)
        upload_file(file)
      end
    else
      upload_file(@source_path)
    end
  end

  def upload_file(file)
    content = File.read(file)
    dropbox_destination = File.join(@dropbox_path, File.basename(file))
    @client.put_file(dropbox_destination, content)
  end
end
