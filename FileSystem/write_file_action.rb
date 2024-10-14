# Description: Sublayer::Action responsible for writing content to a specified file path.
#
# This action allows for easy file writing operations within a Sublayer workflow,
# enabling data persistence or creation of output files from AI-driven processes.
#
# It is initialized with a file_path and file_contents.
# On successful execution, it writes the content to the file at the specified path.
#
# Example usage: When you want to save LLM-generated data to a file for later use.

class WriteFileAction < Sublayer::Actions::Base
  def initialize(file_path:, file_contents:)
    @file_path = file_path
    @file_contents = file_contents
  end

  def call
    begin
      write_to_file
      Sublayer.configuration.logger.log(:info, "Successfully wrote to \\#{@file_path}")
    rescue IOError => e
      error_message = "Error writing to file: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def write_to_file
    File.open(@file_path, 'w') do |file|
      file.write(@file_contents)
    end
  end
end