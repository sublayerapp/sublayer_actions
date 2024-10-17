require 'pdf-reader'

# Description: Sublayer::Action responsible for extracting text from a PDF file.
# This action allows for easy integration of PDF text extraction into Sublayer workflows,
# which can be useful for preparing document content for analysis by AI models or for data extraction tasks.
#
# Requires: 'pdf-reader' gem
# $ gem install pdf-reader
# Or add `gem 'pdf-reader'` to your Gemfile
#
# It is initialized with the path to a PDF file.
# It returns a string containing all the extracted text from the PDF.
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
    raise ArgumentError, "PDF file does not exist" unless File.exist?(@pdf_path)

    reader = PDF::Reader.new(@pdf_path)
    text = reader.pages.map(&:text).join("

")
    
    if text.strip.empty?
      raise StandardError, "No text could be extracted from the PDF"
    end

    text
  end
end