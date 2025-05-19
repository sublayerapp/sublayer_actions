require 'pdf-reader'

# Description: Sublayer::Action responsible for extracting text content from PDF files.
# This action processes PDF documents and extracts their textual content while attempting
# to maintain structural information, making it useful for AI analysis workflows.
#
# Requires: 'pdf-reader' gem
# $ gem install pdf-reader
# Or add `gem 'pdf-reader'` to your Gemfile
#
# It is initialized with a PDF file path and returns the extracted text content.
# The text is formatted to maintain page separation and basic structure.
#
# Example usage: When you want to analyze PDF documents with an LLM, such as processing
# technical documentation, research papers, or business documents.

class PDFTextExtractionAction < Sublayer::Actions::Base
  def initialize(pdf_path:, include_page_numbers: true)
    @pdf_path = pdf_path
    @include_page_numbers = include_page_numbers
  end

  def call
    begin
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
      error_message = "Error extracting text from PDF: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_file
    unless File.exist?(@pdf_path)
      error_message = "PDF file not found at path: #{@pdf_path}"
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
    extracted_text = []

    reader.pages.each_with_index do |page, index|
      page_number = index + 1
      page_text = page.text.strip

      if @include_page_numbers
        extracted_text << "[Page #{page_number}]\n#{page_text}"
      else
        extracted_text << page_text
      end
    end

    Sublayer.configuration.logger.log(:info, "Successfully extracted text from #{reader.pages.count} pages")
    extracted_text.join("\n\n")
  end
end