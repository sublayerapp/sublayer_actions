require 'google/apis/docs_v1'
require 'google/apis/drive_v3'

# Description: Sublayer::Action responsible for creating and populating a new Google Doc.
# This action integrates with Google Docs API to create documents programmatically,
# allowing for AI-generated content to be directly written to collaborative documents.
#
# Requires: 'google-apis-docs_v1' and 'google-apis-drive_v3' gems
# $ gem install google-apis-docs_v1 google-apis-drive_v3
# Or add to your Gemfile:
# gem 'google-apis-docs_v1'
# gem 'google-apis-drive_v3'
#
# It is initialized with a title and content for the document, and optionally a parent folder ID.
# It returns the ID of the created Google Doc.
#
# Example usage: When you want to generate long-form content like reports or documentation
# directly into a Google Doc for collaborative editing and sharing.

class GoogleDocCreateAction < Sublayer::Actions::Base
  def initialize(title:, content:, parent_folder_id: nil)
    @title = title
    @content = content
    @parent_folder_id = parent_folder_id
    setup_clients
  end

  def call
    begin
      doc_id = create_empty_doc
      populate_doc(doc_id)
      move_to_folder(doc_id) if @parent_folder_id

      Sublayer.configuration.logger.log(:info, "Successfully created Google Doc: #{doc_id}")
      doc_id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Doc: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_clients
    @docs = Google::Apis::DocsV1::DocsService.new
    @drive = Google::Apis::DriveV3::DriveService.new
    
    # Configure authorization using service account or OAuth2
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_APPLICATION_CREDENTIALS']),
      scope: [
        'https://www.googleapis.com/auth/documents',
        'https://www.googleapis.com/auth/drive.file'
      ]
    )

    @docs.authorization = credentials
    @drive.authorization = credentials
  end

  def create_empty_doc
    document = {
      title: @title
    }
    
    result = @docs.create_document(document)
    result.document_id
  end

  def populate_doc(doc_id)
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
    @docs.batch_update_document(doc_id, request)
  end

  def move_to_folder(doc_id)
    # First retrieve the file from root
    file = @drive.get_file(
      doc_id,
      fields: 'parents'
    )

    # Remove the file from root and add to specified folder
    previous_parents = file.parents.join(',')
    
    @drive.update_file(
      doc_id,
      fields: 'id, parents',
      add_parents: @parent_folder_id,
      remove_parents: previous_parents
    )
  end
end