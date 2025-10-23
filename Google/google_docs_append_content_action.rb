require 'google/apis/docs_v1'
require 'google/apis/drive_v3'

# Description: Sublayer::Action responsible for appending content to an existing Google Doc.
# This action allows AI systems to maintain living documents by adding generated content
# to existing Google Docs.
#
# Requires: 'google-apis-docs_v1' and 'google-apis-drive_v3' gems
# $ gem install google-apis-docs_v1 google-apis-drive_v3
# Or add to your Gemfile:
# gem 'google-apis-docs_v1'
# gem 'google-apis-drive_v3'
#
# It is initialized with a document_id and the content to append.
# It returns the document_id to confirm the update was successful.
#
# Example usage: When you want to add AI-generated content to a shared document
# or maintain a living document with automated updates.

class GoogleDocsAppendContentAction < Sublayer::Actions::Base
  def initialize(document_id:, content:)
    @document_id = document_id
    @content = content
    
    @service = Google::Apis::DocsV1::DocsService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.from_env(
      scope: [
        'https://www.googleapis.com/auth/documents',
        'https://www.googleapis.com/auth/drive'
      ]
    )
  end

  def call
    begin
      # Get the current end index of the document
      document = @service.get_document(@document_id)
      end_index = document.body.content.last.end_index

      # Prepare the request to append content
      requests = [
        {
          insert_text: {
            location: {
              index: end_index - 1
            },
            text: "\n#{@content}"
          }
        }
      ]

      # Execute the update
      result = @service.batch_update_document(
        @document_id,
        Google::Apis::DocsV1::BatchUpdateDocumentRequest.new(requests: requests)
      )

      Sublayer.configuration.logger.log(
        :info,
        "Successfully appended content to Google Doc: #{@document_id}"
      )

      @document_id
    rescue Google::Apis::Error => e
      error_message = "Error updating Google Doc: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error appending to Google Doc: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
