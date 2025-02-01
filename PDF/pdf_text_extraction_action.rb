require 'pdf-reader'

# Description: Sublayer::Action responsible for extracting text from a PDF file.
# This action allows for easy integration of PDF text extraction into Sublayer workflows,
# enabling processing of document-based information in AI-driven processes.
#
# Requires: 'pdf-reader' gem
# $ gem install pdf-reader
# Or add `gem 'pdf-reader'` to your Gemfile
#
# It is initialized with the path to the PDF file.
# It returns the extracted text as a string.
#
# Example usage: When you want to extract text from a PDF for further processing or analysis in your Sublayer workflow.

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
    text = reader.pages.map(&:text).join("\n")
    
    text.strip
  end
end
