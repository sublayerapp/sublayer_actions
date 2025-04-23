require 'pdf-reader'

# Description: Sublayer::Action responsible for extracting text content from PDF files.
# This action is useful for processing document-based information before feeding it into 
# Sublayer generators or other AI workflows.
#
# Requires: 'pdf-reader' gem
# $ gem install pdf-reader
# Or add `gem 'pdf-reader'` to your Gemfile
#
# It is initialized with the path to a PDF file.
# It returns the extracted text content as a string.
#
# Example usage: When you want to extract text from a PDF for further processing or analysis in an AI workflow.

class PDFTextExtractAction < Sublayer::Actions::Base
  def initialize(pdf_path:)
    @pdf_path = pdf_path
  end

  def call
    begin
      extract_text
    rescue StandardError => e
      error_message = "Error extracting text from PDF: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def extract_text
    raise StandardError, "PDF file not found" unless File.exist?(@pdf_path)

    reader = PDF::Reader.new(@pdf_path)
    text_content = reader.pages.map(&:text).join("\n")

    if text_content.strip.empty?
      Sublayer.configuration.logger.log(:warn, "Extracted text is empty. The PDF might be scanned or have no extractable text.")
    else
      Sublayer.configuration.logger.log(:info, "Successfully extracted text from PDF: #{@pdf_path}")
    end

    text_content
  end
end