require 'pdf-reader'

# Description: Sublayer::Action responsible for extracting clean, formatted text from PDF files.
# This action processes PDF documents and returns their textual content while preserving
# the document's structure and removing common PDF artifacts.
#
# Requires: 'pdf-reader' gem
# $ gem install pdf-reader
# Or add `gem 'pdf-reader'` to your Gemfile
#
# It is initialized with a PDF file path and returns the extracted text content.
#
# Example usage: When you want to extract text from PDF documents for analysis by an LLM
# or for processing in an AI-driven workflow.

class PdfTextExtractionAction < Sublayer::Actions::Base
  def initialize(pdf_path:, preserve_formatting: true)
    @pdf_path = pdf_path
    @preserve_formatting = preserve_formatting
  end

  def call
    validate_file
    extract_text
  rescue PDF::Reader::MalformedPDFError => e
    error_message = "Malformed PDF error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue PDF::Reader::UnsupportedFeatureError => e
    error_message = "Unsupported PDF feature: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error processing PDF: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def validate_file
    unless File.exist?(@pdf_path)
      error_message = "PDF file not found: #{@pdf_path}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    unless File.extname(@pdf_path).downcase == '.pdf'
      error_message = "File is not a PDF: #{@pdf_path}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def extract_text
    reader = PDF::Reader.new(@pdf_path)
    extracted_text = ""

    reader.pages.each_with_index do |page, index|
      page_text = clean_text(page.text)
      
      if @preserve_formatting
        extracted_text += "--- Page #{index + 1} ---\n"
        extracted_text += page_text + "\n\n"
      else
        extracted_text += page_text + " "
      end
    end

    Sublayer.configuration.logger.log(:info, "Successfully extracted text from #{@pdf_path}")
    extracted_text.strip
  end

  def clean_text(text)
    # Remove common PDF artifacts and normalize whitespace
    text
      .gsub(/\r\n?/, "\n")           # Normalize line endings
      .gsub(/[\u0000-\u0008\u000B\u000C\u000E-\u001F]/, "") # Remove control characters
      .gsub(/\s+/, " ")            # Normalize multiple spaces
      .gsub(/\n\s*\n+/, "\n\n")    # Normalize multiple blank lines
      .strip
  end
end
