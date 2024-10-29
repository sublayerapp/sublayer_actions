# Description: Sublayer::Action responsible for appending content to an existing file.
# This action is useful for logging additional information or updating configuration files without rewriting them completely.
#
# It is initialized with a file_path and content_to_append.
# On successful execution, it appends the content to the file at the specified path.
#
# Example usage: When you want to log additional information or update a configuration file incrementally.

class AppendToFileAction < Sublayer::Actions::Base
  def initialize(file_path:, content_to_append:)
    @file_path = file_path
    @content_to_append = content_to_append
  end

  def call
    begin
      append_to_file
      Sublayer.configuration.logger.log(:info, "Successfully appended to #{@file_path}")
    rescue IOError => e
      error_message = "Error appending to file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def append_to_file
    File.open(@file_path, 'a') do |file|
      file.write(@content_to_append)
    end
  end
end
