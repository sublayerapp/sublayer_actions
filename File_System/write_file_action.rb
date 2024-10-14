class WriteFileAction < Sublayer::Actions::Base
  def initialize(file_path:, file_contents:)
    @file_path = file_path
    @file_contents = file_contents
  end

  def call
    begin
      File.open(@file_path, 'w') { |file| file.write(@file_contents) }
      Sublayer.configuration.logger.log(:info, "File written successfully to #{@file_path}")
      true
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error writing to file: #{e.message}")
      raise e
    end
  end
end