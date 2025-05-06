require 'pdf-reader'

# Description: Sublayer::Action responsible for extracting text content from PDF files.
# This action enables AI analysis on documents and reports uploaded by users.
#
# Requires: 'pdf-reader' gem
# $ gem install pdf-reader
# Or add `gem 'pdf-reader'` to your Gemfile
#
# It is initialized with the path to a PDF file.
# It returns the extracted text content from the PDF.
#
# Example usage: When you want to extract text from a PDF for further processing or analysis by an AI model.

class PDFTextExtractionAction < Sublayer::Actions::Base
  def initialize(pdf_path:)
    @pdf_path = pdf_path
  end

  def call
    begin
      extracted_text = extract_text_from_pdf
      Sublayer.configuration.logger.log(:info, "Successfully extracted text from PDF: #{@pdf_path}")
      extracted_text
    rescue StandardError => e
      error_message = "Error extracting text from PDF: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def extract_text_from_pdf
    raise StandardError, "PDF file not found" unless File.exist?(@pdf_path)

    reader = PDF::Reader.new(@pdf_path)
    text_content = reader.pages.map(&:text).join("\n")

    if text_content.strip.empty?
      raise StandardError, "No text content found in the PDF"
    end

    text_content
  end
end