# Description: Sublayer::Action responsible for creating a zip archive of a directory.
# It respects a .contextignore file to exclude files and directories.
#
# Initialized with a directory path and an archive name.
# Returns the path to the created zip archive.
#
# Example usage: When you need to package a directory's contents for sharing or backup,
# while excluding certain files or directories specified in a .contextignore file.

require 'zip'

class FileSystemCreateZipArchiveAction < Sublayer::Actions::Base
  def initialize(directory_path:, archive_name:)
    @directory_path = directory_path
    @archive_name = archive_name
    @archive_path = File.join(@directory_path, @archive_name + ".zip")
  end

  def call
    create_zip_archive
  rescue StandardError => e
    error_message = "Error creating zip archive: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def create_zip_archive
    ignored_patterns = load_contextignore
    files = get_files(ignored_patterns)

    Zip::File.open(@archive_path, Zip::File::CREATE) do |zipfile|
      files.each do |file|
        file_path = File.join(@directory_path, file)
        zipfile.add(file, file_path)
      end
    end

    Sublayer.configuration.logger.log(:info, "Successfully created zip archive at #{@archive_path}")
    @archive_path
  end

  def load_contextignore
    contextignore_path = File.join(@directory_path, '.contextignore')
    return [] unless File.exist?(contextignore_path)

    File.readlines(contextignore_path).map(&:strip).reject do |line|
      line.empty? || line.start_with?('#')
    end
  end

  def get_files(ignored_patterns)
    Dir.chdir(@directory_path) do
      all_files = Dir.glob('**/*').select { |f| File.file?(f) }
      all_files.reject do |file|
        ignored_patterns.any? do |pattern|
          File.fnmatch?(pattern, file) ||
            file.start_with?(pattern.chomp('/'))
        end
      end
    end
  end
end