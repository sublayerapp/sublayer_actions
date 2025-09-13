require 'google/apis/docs_v1'
require 'google/apis/drive_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for appending content to an existing Google Doc.
# This action integrates with Google Docs API to add content to the end of a specified document.
#
# Requires: Google Cloud project with Docs API enabled and appropriate credentials
# - google-api-client gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# Environment variables needed:
# - GOOGLE_CREDENTIALS: Path to service account JSON key file or the JSON content itself
#
# It is initialized with a document_id and the content to append.
# Returns the updated document's revision ID on success.
#
# Example usage: When you want an AI agent to log information, generate reports,
# or contribute to collaborative documents.

class GoogleDocsAppendContentAction < Sublayer::Actions::Base
  def initialize(document_id:, content:)
    @document_id = document_id
    @content = content
    @service = initialize_service
  end

  def call
    begin
      # Get the current document to find its length
      document = @service.get_document(@document_id)
      end_index = document.body.content.length - 1

      # Prepare the request to append content
      requests = [
        {
          insert_text: {
            location: {
              index: end_index
            },
            text: "\n#{@content}"
          }
        }
      ]

      # Execute the update
      result = @service.batch_update_document(
        @document_id,
        {
          requests: requests
        }
      )

      Sublayer.configuration.logger.log(:info, "Successfully appended content to Google Doc: #{@document_id}")
      result.document_id
    rescue Google::Apis::Error => e
      error_message = "Error appending to Google Doc: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_service
    service = Google::Apis::DocsV1::DocsService.new
    
    # Load credentials from environment variable or file
    credentials = if ENV['GOOGLE_CREDENTIALS'].include?('{')
      Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(ENV['GOOGLE_CREDENTIALS']),
        scope: [
          'https://www.googleapis.com/auth/documents',
          'https://www.googleapis.com/auth/drive'
        ]
      )
    else
      Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(ENV['GOOGLE_CREDENTIALS']),
        scope: [
          'https://www.googleapis.com/auth/documents',
          'https://www.googleapis.com/auth/drive'
        ]
      )
    end

    service.authorization = credentials
    service
  rescue StandardError => e
    error_message = "Error initializing Google Docs service: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end