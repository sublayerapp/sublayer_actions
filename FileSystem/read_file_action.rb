# Description: Sublayer::Action responsible for reading content from a specified file path.
#
# This action allows for easy file reading operations within a Sublayer workflow,
# enabling data retrieval or input for AI-driven processes.
#
# It is initialized with a file_path.
# On successful execution, it returns the content of the file at the specified path.
#
# Example usage: When you want to read data from a file for use in an LLM-driven process.

class ReadFileAction < Sublayer::Actions::Base
  def initialize(file_path:)
    @file_path = file_path
  end

  def call
    begin
      content = read_from_file
      Sublayer.configuration.logger.log(:info, "Successfully read from #{@file_path}")
      content
    rescue Errno::ENOENT => e
      error_message = "Error: File not found - #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue IOError => e
      error_message = "Error reading from file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def read_from_file
    File.read(@file_path)
  end
end