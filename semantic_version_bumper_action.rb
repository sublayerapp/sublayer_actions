module Sublayer
  module Actions
    class SemanticVersionBumperAction < Sublayer::Actions::Base
      def initialize(project_path:, version_file_path: 'VERSION')
        @project_path = project_path
        @version_file_path = version_file_path
      end

      def call
        version = read_version
        commit_messages = fetch_commit_messages
        new_version = bump_version(version, commit_messages)
        write_new_version(new_version)
      rescue StandardError => e
        log_error("Error during version bumping: #{e.message}")
        raise
      end

      private

      def read_version
        version_file = File.join(@project_path, @version_file_path)
        unless File.exist?(version_file)
          log_error("Version file not found at #{version_file}")
          raise "Version file not found at #{version_file}"
        end

        File.read(version_file).strip
      end

      def fetch_commit_messages
        Dir.chdir(@project_path) do
          `git log --pretty=format:%s`.split("\n")
        end
      end

      def bump_version(version, commit_messages)
        major, minor, patch = version.split('.').map(&:to_i)

        commit_messages.each do |message|
          case message
          when /BREAKING CHANGE/i
            major += 1
            minor = 0
            patch = 0
          when /feat/i
            minor += 1
            patch = 0
          when /fix/i
            patch += 1
          end
        end

        "#{major}.#{minor}.#{patch}"
      end

      def write_new_version(new_version)
        version_file = File.join(@project_path, @version_file_path)
        File.open(version_file, 'w') { |file| file.write(new_version) }
        log_info("Updated version to #{new_version}")
      end

      def log_error(message)
        # Assume there is a predefined logging mechanism
        puts "ERROR: #{message}"
      end

      def log_info(message)
        # Assume there is a predefined logging mechanism
        puts "INFO: #{message}"
      end
    end
  end
end