require 'pdf-reader'

# Description: Sublayer::Action responsible for extracting text content from PDF files.
# This action maintains the structure and formatting of the text for better analysis
# and processing in AI-driven workflows.
#
# Requires: 'pdf-reader' gem
# $ gem install pdf-reader
# Or add `gem 'pdf-reader'` to your Gemfile
#
# It is initialized with a PDF file path and returns the extracted text content.
# The text maintains basic structural elements like paragraphs and pages.
#
# Example usage: When you want to analyze PDF documents as part of an AI workflow,
# such as extracting information for analysis or summarization by an LLM.

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
      error_message = "Invalid or corrupted PDF file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error extracting text from PDF: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
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
    content = []

    reader.pages.each_with_index do |page, index|
      page_number = index + 1
      
      # Extract text from the current page
      page_text = page.text.strip

      # Skip empty pages
      next if page_text.empty?

      # Add page number if requested
      if @include_page_numbers
        content << "[Page #{page_number}]\n#{page_text}"
      else
        content << page_text
      end
    end

    # Join all pages with clear separation
    extracted_text = content.join("\n\n")

    Sublayer.configuration.logger.log(:info, "Successfully extracted text from PDF: #{@pdf_path}")
    extracted_text
  end
end