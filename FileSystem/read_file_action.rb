# Description: Sublayer::Action responsible for reading contents from a specified file path.
# This action is useful for retrieving data stored in files for processing or passing to subsequent actions.
#
# It is initialized with a file_path and returns the file contents upon execution.
#
# Example usage: When you want to retrieve data from a file to use in a subsequent action in the Sublayer workflow.

class ReadFileAction < Sublayer::Actions::Base
  def initialize(file_path:)
    @file_path = file_path
  end

  def call
    read_file_content
  end

  private

  def read_file_content
    begin
      content = File.read(@file_path)
      Sublayer.configuration.logger.log(:info, "Successfully read file: #{@file_path}")
      content
    rescue Errno::ENOENT => e
      error_message = "File not found: #{@file_path}. Error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue IOError => e
      error_message = "Error reading file: #{@file_path}. Error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end