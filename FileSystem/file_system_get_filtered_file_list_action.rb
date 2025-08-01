# Description: Sublayer::Action responsible for retrieving a list of files within a specified directory (and optionally its subdirectories) that match certain criteria (e.g., file extension, modification date, size).
#
# It is initialized with a directory path, a filter (as a hash), and a boolean to indicate whether to search subdirectories.
# The filter can include keys like 'extension', 'modified_before', 'modified_after', 'min_size', 'max_size'.
# It returns an array of file paths that match the specified criteria.
#
# Example usage: When you need to find specific files within a directory for processing or analysis based on certain criteria.

require 'find'

class FileSystemGetFilteredFileListAction < Sublayer::Actions::Base
  def initialize(directory_path:, filter: {}, search_subdirectories: false)
    @directory_path = directory_path
    @filter = filter
    @search_subdirectories = search_subdirectories
  end

  def call
    begin
      matching_files = find_matching_files
      Sublayer.configuration.logger.log(:info, "Found \#{matching_files.size} matching files in \#{@directory_path}")
      matching_files
    rescue StandardError => e
      error_message = "Error finding files: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def find_matching_files
    files = []
    search_method = @search_subdirectories ? Find.method(:find) : Dir.method(:entries)

    search_method.call(@directory_path) do |path|
      next if File.directory?(path)

      if matches_filter?(path)
        files << path
      end
    end
    files
  end

  def matches_filter?(file_path)
    return false unless File.exist?(file_path)

    @filter.each do |key, value|
      case key
      when 'extension'
        return false unless File.extname(file_path) == "." + value.to_s
      when 'modified_before'
        return false unless File.mtime(file_path) < Time.parse(value.to_s)
      when 'modified_after'
        return false unless File.mtime(file_path) > Time.parse(value.to_s)
      when 'min_size'
        return false unless File.size(file_path) >= value.to_i
      when 'max_size'
        return false unless File.size(file_path) <= value.to_i
      end
    end
    true
  end
end