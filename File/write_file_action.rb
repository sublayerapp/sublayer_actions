# Description: Sublayer::Action responsible for writing content to a specific file path.
# This action allows for easy file writing operations within the Sublayer AI framework.
#
# It is initialized with a file_path and file_contents.
# It returns true if the file was successfully written, false otherwise.
#
# Example usage: When you want to save generated content, logs, or any other data to a file.

class WriteFileAction < Sublayer::Actions::Base
  def initialize(file_path:, file_contents:)
    @file_path = file_path
    @file_contents = file_contents
  end

  def call
    begin
      File.write(@file_path, @file_contents)
      Sublayer.configuration.logger.log(:info, "File successfully written to #{@file_path}")
      true
    rescue IOError => e
      error_message = "Error writing to file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      false
    rescue SystemCallError => e
      error_message = "System error writing to file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      false
    end
  end
end