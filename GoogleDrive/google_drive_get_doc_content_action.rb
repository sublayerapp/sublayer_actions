require 'google/apis/docs_v1'
require 'google/apis/drive_v3'

# Description: Sublayer::Action responsible for retrieving the content of a Google Doc by its document ID.
# This action integrates with Google Docs API to fetch document content for use in AI workflows.
#
# Requires: Google API gems
# $ gem install google-apis-docs_v1 google-apis-drive_v3
# Or add to your Gemfile:
# gem 'google-apis-docs_v1'
# gem 'google-apis-drive_v3'
#
# It is initialized with a document_id and returns the plain text content of the Google Doc.
#
# Example usage: When you want to analyze, summarize, or transform the content of a Google Doc
# using a Sublayer::Generator.

class GoogleDriveGetDocContentAction < Sublayer::Actions::Base
  def initialize(document_id:)
    @document_id = document_id
    @service = Google::Apis::DocsV1::DocsService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CLOUD_CREDENTIALS']),
      scope: [
        'https://www.googleapis.com/auth/documents.readonly',
        'https://www.googleapis.com/auth/drive.readonly'
      ]
    )
  end

  def call
    begin
      document = @service.get_document(@document_id)
      content = extract_text_content(document)
      Sublayer.configuration.logger.log(:info, "Successfully retrieved content from Google Doc: #{@document_id}")
      content
    rescue Google::Apis::AuthorizationError => e
      error_message = "Authorization error accessing Google Doc: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::ClientError => e
      error_message = "Client error accessing Google Doc (document may not exist): #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error retrieving Google Doc content: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def extract_text_content(document)
    # Initialize an empty string to store the document content
    content = ""

    # Iterate through the document's structural elements
    document.body.content.each do |structural_element|
      if structural_element.paragraph
        structural_element.paragraph.elements.each do |element|
          content += element.text_run.content if element.text_run&.content
        end
      end
    end

    content.strip
  end
end