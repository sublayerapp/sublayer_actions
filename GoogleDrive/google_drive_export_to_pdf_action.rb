require 'google/apis/drive_v3'
require 'google/apis/docs_v1'

# Description: Sublayer::Action responsible for exporting a Google Doc or Sheet to PDF format.
# This action takes a Google Drive file ID and exports it to PDF, returning either the raw PDF content
# or a downloadable URL.
#
# Requires:
# - google-api-client gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# Environment Variables Required:
# - GOOGLE_DRIVE_CREDENTIALS: JSON string of service account credentials
#
# It is initialized with a file_id and optional return_type parameter ('content' or 'url').
# It returns either the PDF content as a binary string or a download URL for the PDF.
#
# Example usage: When you want to generate PDF documentation from AI-populated Google Docs,
# or create PDF reports from data collected in Google Sheets.

class GoogleDriveExportToPdfAction < Sublayer::Actions::Base
  MIME_TYPE_PDF = 'application/pdf'
  SUPPORTED_MIME_TYPES = [
    'application/vnd.google-apps.document',  # Google Doc
    'application/vnd.google-apps.spreadsheet' # Google Sheet
  ]

  def initialize(file_id:, return_type: 'content')
    @file_id = file_id
    @return_type = return_type # 'content' or 'url'
    setup_client
  end

  def call
    begin
      # Get the file metadata to verify it exists and check its type
      file = @drive_service.get_file(
        @file_id,
        fields: 'mimeType'
      )

      unless SUPPORTED_MIME_TYPES.include?(file.mime_type)
        raise StandardError, "Unsupported file type: #{file.mime_type}"
      end

      export_to_pdf
    rescue Google::Apis::Error => e
      error_message = "Google API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error exporting file to PDF: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def setup_client
    credentials = Google::Auth::ServiceAccountCredentials.from_json(
      ENV['GOOGLE_DRIVE_CREDENTIALS']
    ).configure_connection

    @drive_service = Google::Apis::DriveV3::DriveService.new
    @drive_service.authorization = credentials
  end

  def export_to_pdf
    if @return_type == 'content'
      content = @drive_service.export_file(
        @file_id,
        MIME_TYPE_PDF,
        download_dest: StringIO.new
      ).string

      Sublayer.configuration.logger.log(
        :info,
        "Successfully exported file #{@file_id} to PDF"
      )

      content
    else # return_type == 'url'
      url = @drive_service.export_file(
        @file_id,
        MIME_TYPE_PDF,
        download_dest: nil
      )

      Sublayer.configuration.logger.log(
        :info,
        "Generated PDF download URL for file #{@file_id}"
      )

      url
    end
  end
end