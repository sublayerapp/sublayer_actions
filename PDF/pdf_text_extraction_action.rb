require 'pdf-reader'

# Description: Sublayer::Action responsible for extracting text content from a PDF file.
# This action allows for easy integration of PDF text extraction into Sublayer workflows,
# enabling document analysis and processing capabilities.
#
# Requires: 'pdf-reader' gem
# $ gem install pdf-reader
# Or add `gem 'pdf-reader'` to your Gemfile
#
# It is initialized with a file_path to the PDF file.
# It returns a string containing all the extracted text from the PDF.
#
# Example usage: When you want to extract text from a PDF for further processing or analysis in your Sublayer workflow.

class PDFTextExtractionAction < Sublayer::Actions::Base
  def initialize(file_path:)
    @file_path = file_path
  end

  def call
    begin
      extracted_text = extract_text_from_pdf
      Sublayer.configuration.logger.log(:info, "Successfully extracted text from PDF: #{@file_path}")
      extracted_text
    rescue StandardError => e
      error_message = "Error extracting text from PDF: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def extract_text_from_pdf
    raise StandardError, "PDF file not found: #{@file_path}" unless File.exist?(@file_path)

    reader = PDF::Reader.new(@file_path)
    text = reader.pages.map(&:text).join("\n")

    if text.strip.empty?
      Sublayer.configuration.logger.log(:warn, "Extracted text is empty. The PDF might be scanned or have no extractable text.")
    end

    text
  end
end