require 'pdf-reader'

# Description: Sublayer::Action responsible for extracting text content from PDF files.
# This action allows for easy integration of PDF content extraction into AI workflows,
# enabling analysis and processing of document content.
#
# Requires: 'pdf-reader' gem
# $ gem install pdf-reader
# Or add `gem 'pdf-reader'` to your Gemfile
#
# It is initialized with a file_path to the PDF file.
# It returns the extracted text content as a string.
#
# Example usage: When you want to extract text from a PDF for further processing or analysis in an AI workflow.

class PDFTextExtractionAction < Sublayer::Actions::Base
  def initialize(file_path:)
    @file_path = file_path
  end

  def call
    begin
      reader = PDF::Reader.new(@file_path)
      text_content = reader.pages.map(&:text).join('\n')
      
      Sublayer.configuration.logger.log(:info, "Successfully extracted text from PDF: #{@file_path}")
      text_content
    rescue PDF::Reader::MalformedPDFError => e
      error_message = "Error: Malformed PDF file - #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Errno::ENOENT => e
      error_message = "Error: File not found - #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error extracting text from PDF: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end