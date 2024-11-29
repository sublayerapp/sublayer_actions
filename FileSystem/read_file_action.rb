class ReadFileAction < Sublayer::Actions::Base
  def initialize(file_path:)
    @file_path = file_path
  end

  def call
    begin
      file_contents = File.read(@file_path)
      Sublayer.configuration.logger.log(:info, "Successfully read file: #{@file_path}")
      file_contents
    rescue Errno::ENOENT => e
      error_message = "File not found: #{@file_path} - #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error reading file: #{@file_path} - #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end