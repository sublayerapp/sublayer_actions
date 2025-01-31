require 'pdf-reader'

# Description: Sublayer::Action responsible for reading the contents of a PDF file and generating a concise summary.
# Especially useful for document processing and analysis tasks where only the key points of a document are needed.

class PdfContentSummarizerAction < Sublayer::Actions::Base
  def initialize(file_path:)
    @file_path = file_path
  end

  def call
    begin
      content = extract_pdf_content
      summary = generate_summary(content)
      Sublayer.configuration.logger.log(:info, "Successfully summarized PDF content from \\#{@file_path}")
      summary
    rescue IOError => e
      error_message = "Error reading PDF file: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "An error occurred: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def extract_pdf_content
    reader = PDF::Reader.new(@file_path)
    reader.pages.map(&:text).join("\n")
  end

  def generate_summary(content)
    # For demonstration purposes, we assume a simple summary logic.
    # In a real-world scenario, an NLP library or service would be used to generate the summary.
    content.split("\n").first(3).join(" ").slice(0, 500) + '...'
  end
end
