require 'google/apis/docs_v1'
require 'google/apis/drive_v3'

# Description: Sublayer::Action responsible for creating a new Google Doc and populating it with content.
# This action enables automated document creation and content population within Google Docs.
#
# Requires: 'google-apis-docs_v1' and 'google-apis-drive_v3' gems
# $ gem install google-apis-docs_v1 google-apis-drive_v3
# Or add to your Gemfile:
# gem 'google-apis-docs_v1'
# gem 'google-apis-drive_v3'
#
# It is initialized with a title and content for the document, and optionally a parent folder ID.
# It returns a hash containing the document ID and URL.
#
# Example usage: When you want to create a new Google Doc with AI-generated content
# like reports, documentation, or any other textual content.

class GoogleDocCreateAction < Sublayer::Actions::Base
  def initialize(title:, content:, parent_folder_id: nil)
    @title = title
    @content = content
    @parent_folder_id = parent_folder_id
    
    # Initialize the Google Docs and Drive APIs
    @docs_service = Google::Apis::DocsV1::DocsService.new
    @drive_service = Google::Apis::DriveV3::DriveService.new
    
    # Configure the services with credentials
    credentials = JSON.parse(ENV['GOOGLE_CREDENTIALS'])
    scope = [
      'https://www.googleapis.com/auth/documents',
      'https://www.googleapis.com/auth/drive.file'
    ]
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(credentials.to_json),
      scope: scope
    )
    
    @docs_service.authorization = authorizer
    @drive_service.authorization = authorizer
  end

  def call
    begin
      # Create a new document
      document = create_document
      
      # Move to specified folder if provided
      move_to_folder(document.document_id) if @parent_folder_id
      
      # Insert content into the document
      populate_content(document.document_id)
      
      # Return document details
      result = {
        document_id: document.document_id,
        url: "https://docs.google.com/document/d/#{document.document_id}/edit"
      }
      
      Sublayer.configuration.logger.log(:info, "Successfully created Google Doc: #{result[:url]}")
      result
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Doc: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_document
    doc = Google::Apis::DocsV1::Document.new(title: @title)
    @docs_service.create_document(doc)
  end

  def move_to_folder(document_id)
    file = @drive_service.get_file(
      document_id,
      fields: 'parents'
    )

    previous_parents = file.parents.join(',') if file.parents

    @drive_service.update_file(
      document_id,
      {}
    ) do |f|
      f.add_query_param('addParents', @parent_folder_id)
      f.add_query_param('removeParents', previous_parents) if previous_parents
    end
  end

  def populate_content(document_id)
    requests = [
      {
        insert_text: {
          location: {
            index: 1
          },
          text: @content
        }
      }
    ]

    request = Google::Apis::DocsV1::BatchUpdateDocumentRequest.new(requests: requests)
    @docs_service.batch_update_document(document_id, request)
  end
end