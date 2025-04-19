# Description: Sublayer::Action responsible for converting a file to plain text.
# It uses the 'extract_text' gem to handle various file types like PDF, DOC, DOCX, etc.
#
# Requires: gem install extract_text
#
# It is initialized with a file_path and returns the extracted text content.
#
# Example usage: When you want to extract text from a file to use as input for an LLM.

require 'extract_text'

class FileSystemConvertFileToTextAction < Sublayer::Actions::Base
  def initialize(file_path:)
    @file_path = file_path
  end

  def call
    begin
      text = ExtractText.extract_text @file_path
      Sublayer.configuration.logger.log(:info, "Successfully converted \#{@file_path} to text.")
      text
    rescue StandardError => e
      error_message = "Error converting file to text: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end