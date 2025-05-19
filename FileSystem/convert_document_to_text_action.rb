# Description: Sublayer::Action that converts a document (e.g., PDF, DOCX) to plain text.
# This is useful for extracting content from various file formats for use in generators or other actions.
#
# Requires: `docx` and `pdf-reader` gems.
# $ gem install docx pdf-reader
# Or add `gem 'docx'` and `gem 'pdf-reader'` to your Gemfile
#
# It is initialized with a file_path and returns the text content of the document.
#
# Example usage: When you want to extract text from a document to use it as context in a prompt.

class ConvertDocumentToTextAction < Sublayer::Actions::Base
  def initialize(file_path:)
    @file_path = file_path
  end

  def call
    begin
      text = extract_text
      Sublayer.configuration.logger.log(:info, "Successfully converted document to text: #{@file_path}")
      text
    rescue StandardError => e
      error_message = "Error converting document to text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def extract_text
    file_extension = File.extname(@file_path).downcase
    case file_extension
    when '.pdf'
      extract_text_from_pdf
    when '.docx'
      extract_text_from_docx
    else
      raise "Unsupported file format: #{file_extension}"
    end
  end

  def extract_text_from_pdf
    require 'pdf-reader'
    reader = PDF::Reader.new(@file_path)
    reader.pages.map(&:text).join("\n")
  end

  def extract_text_from_docx
    require 'docx'
    doc = Docx::Document.open(@file_path)
    doc.paragraphs.map(&:to_s).join("\n")
  end
end