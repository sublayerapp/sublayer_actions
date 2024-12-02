# Description: Sublayer::Action for managing files and folders in Google Drive.
# Supports uploading, downloading, creating folders, moving/copying files, and searching.
#
# Requires: google_drive gem
# gem install google_drive

class GoogleDriveFileManagementAction < Sublayer::Actions::Base
  def initialize(operation:, file_path: nil, folder_id: nil, destination_folder_id: nil, search_query: nil, file_contents: nil, mime_type: nil)
    @operation = operation
    @file_path = file_path
    @folder_id = folder_id
    @destination_folder_id = destination_folder_id
    @search_query = search_query
    @file_contents = file_contents
    @mime_type = mime_type

    @session = GoogleDrive::Session.from_config("config.json") # Assumes config.json is set up
  end

  def call
    begin
      case @operation
      when :upload
        upload_file
      when :download
        download_file
      when :create_folder
        create_folder
      when :move_or_copy
        move_or_copy_file
      when :search
        search_files
      else
        raise ArgumentError, "Invalid operation: #{@operation}"
      end
    rescue GoogleDrive::Error, ArgumentError => e
      Sublayer.configuration.logger.log(:error, "Google Drive operation failed: #{e.message}")
      raise e
    end
  end

  private

  def upload_file
    file = @session.upload_from_file(@file_path, nil, convert: false)
    if @folder_id
      folder = @session.get_folder_by_id(@folder_id)
      folder.add(file)
    end
    file.id
  end

  def download_file
    file = @session.file_by_id(@file_path) # file_path is used as file_id here
    file.download_to_file("downloaded_file") # Or specify a custom download path
  end

  def create_folder
    @session.collection_by_title(@folder_id).create_subcollection(@file_path).id # folder_id as parent, file_path as new folder name
  end

  def move_or_copy_file
    file = @session.file_by_id(@file_path)
    destination_folder = @session.get_folder_by_id(@destination_folder_id)
    if @operation == :move
      file.move(destination_folder)
    else
      file.copy(destination_folder)
    end
  end

  def search_files
    @session.files(q: @search_query)
  end
end