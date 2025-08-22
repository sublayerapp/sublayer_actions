# Description: Sublayer::Action responsible for converting a document (txt, pdf, docx, etc.) into a string.
#
# This action uses the 'docx' and 'pdf-reader' gems to handle .docx and .pdf files, respectively.
# Please ensure these gems are installed before using this action.
#
# It is initialized with a file_path to the document.
# It returns the content of the document as a string.
#
# Example usage: When you want to feed the content of a local document into a Sublayer::Generator for use in a prompt.

class ConvertDocumentToStringAction < Sublayer::Actions::Base
  def initialize(file_path:)
    @file_path = file_path
  end

  def call
    begin
      text = extract_text
      Sublayer.configuration.logger.log(:info, "Successfully converted document \#{@file_path} to string.")
      text
    rescue StandardError => e
      error_message = "Error converting document \#{@file_path} to string: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def extract_text
    file_extension = File.extname(@file_path).downcase

    case file_extension
    when ".txt"
      File.read(@file_path)
    when ".pdf"
      require 'pdf-reader'
      reader = PDF::Reader.new(@file_path)
      reader.pages.map(&:text).join("\n")
    when ".docx"
      require 'docx'
      doc = Docx::Document.open(@file_path)
      doc.paragraphs.map(&:to_s).join("\n")
    else
      raise "Unsupported file type: #{file_extension}"
    end
  end
end