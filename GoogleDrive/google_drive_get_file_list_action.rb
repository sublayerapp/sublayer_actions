require 'google/apis/drive_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

# Description: Sublayer::Action responsible for retrieving a list of files in a given Google Drive folder.
#
# It is initialized with a folder_id and returns an array of file names and IDs.
#
# Example usage: When you want to process multiple files in a Google Drive folder, e.g., summarizing documents or converting file formats.

class GoogleDriveGetFileListAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Sublayer Google Drive'.freeze
  CREDENTIALS_PATH = 'token.yaml'.freeze

  def initialize(folder_id:)
    @folder_id = folder_id
    @client_secrets_path = ENV['GOOGLE_CLIENT_SECRETS_PATH'] # Path to your client_secrets.json
  end

  def call
    service = get_drive_service
    file_list(service)
  rescue StandardError => e
    error_message = "Error retrieving Google Drive file list: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization request. If authorization
  # request, the user's consent will be secured persisting the refresh token
  # to disk.  This will also cause the blocking call to refresh the token.
  def authorize
    client_id = Google::Auth::ClientId.from_file(@client_secrets_path)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, Google::Apis::DriveV3::AUTH_DRIVE_READONLY, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts 'Open the following URL in the browser and enter the '
           'resulting code after authorization:'
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end

  def get_drive_service
    # Initialize the API
    service = Google::Apis::DriveV3::DriveService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
    service
  end

  def file_list(service)
    # List files in the specified folder
    query = "'#{@folder_id}' in parents and trashed = false"
    fields = 'files(id, name)'
    response = service.list_files(q: query, fields: fields)

    files = response.files.map { |file| { name: file.name, id: file.id } }
    Sublayer.configuration.logger.log(:info, "Retrieved #{files.count} files from Google Drive folder #{@folder_id}")
    files
  end
end