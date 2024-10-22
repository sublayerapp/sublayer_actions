require 'pdf-reader'

# Description: Sublayer::Action responsible for extracting text content from PDF files.
# This action is useful for AI systems that need to process information from PDF documents.
#
# It is initialized with a file path to the PDF.
# It returns the extracted text content as a string.
#
# Example usage: When you want to extract text from a PDF to use in a Sublayer::Generator for analysis or processing.

class PDFTextExtractionAction < Sublayer::Actions::Base
  def initialize(file_path:)
    @file_path = file_path
  end

  def call
    begin
      raise ArgumentError, 'File path is nil or empty' if @file_path.nil? || @file_path.empty?
      raise ArgumentError, 'File does not exist' unless File.exist?(@file_path)
      raise ArgumentError, 'File is not a PDF' unless File.extname(@file_path).downcase == '.pdf'

      reader = PDF::Reader.new(@file_path)
      text_content = reader.pages.map(&:text).join('
')

      Sublayer.configuration.logger.log(:info, "Successfully extracted text from PDF: #{@file_path}")
      text_content
    rescue ArgumentError => e
      Sublayer.configuration.logger.log(:error, "Invalid argument for PDF extraction: #{e.message}")
      raise e
    rescue PDF::Reader::MalformedPDFError => e
      Sublayer.configuration.logger.log(:error, "Malformed PDF error: #{e.message}")
      raise e
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error extracting text from PDF: #{e.message}")
      raise e
    end
  end
end
