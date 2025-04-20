require 'google/apis/docs_v1'
require 'google/apis/drive_v3'

# Description: Sublayer::Action responsible for creating a new Google Doc with specified content
# and optional sharing settings. This action enables workflows where AI-generated content
# needs to be collaborated on in Google Docs format.
#
# Requires: 'google-apis-docs_v1' and 'google-apis-drive_v3' gems
# $ gem install google-apis-docs_v1 google-apis-drive_v3
# Or add to your Gemfile:
# gem 'google-apis-docs_v1'
# gem 'google-apis-drive_v3'
#
# It is initialized with a title and content, and optionally sharing settings.
# It returns a hash containing the document ID and URL.
#
# Example usage: When you want to create a Google Doc from AI-generated content
# that needs to be collaboratively edited or reviewed by a team.

class GoogleDocCreateAction < Sublayer::Actions::Base
  def initialize(title:, content:, share_with: [], share_mode: 'reader')
    @title = title
    @content = content
    @share_with = share_with  # Array of email addresses
    @share_mode = share_mode  # 'reader', 'commenter', or 'writer'
    
    @docs_service = Google::Apis::DocsV1::DocsService.new
    @drive_service = Google::Apis::DriveV3::DriveService.new
    
    # Assuming credentials are stored in environment variable or configuration
    credentials = Google::Auth::ServiceAccountCredentials.from_env(
      scope: [
        'https://www.googleapis.com/auth/documents',
        'https://www.googleapis.com/auth/drive'
      ]
    )
    
    @docs_service.authorization = credentials
    @drive_service.authorization = credentials
  end

  def call
    begin
      # Create the document
      document = create_document
      
      # Insert the content
      insert_content(document.document_id)
      
      # Set sharing permissions if specified
      share_document(document.document_id) unless @share_with.empty?
      
      # Return the document information
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
    document = Google::Apis::DocsV1::Document.new(title: @title)
    @docs_service.create_document(document)
  end

  def insert_content(document_id)
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

  def share_document(document_id)
    @share_with.each do |email|
      permission = Google::Apis::DriveV3::Permission.new(
        type: 'user',
        role: @share_mode,
        email_address: email
      )
      
      @drive_service.create_permission(
        document_id,
        permission,
        send_notification_email: true
      )
    end
  end
end