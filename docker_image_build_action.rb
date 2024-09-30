require 'open3'

module Sublayer
  module Actions
    class DockerImageBuildAction < Sublayer::Actions::Base
      def initialize(context, options = {})
        super
        @dockerfile_path = options[:dockerfile_path] || 'Dockerfile'
        @image_name = options[:image_name]
        @image_tag = options[:image_tag] || 'latest'
        @build_args = options[:build_args] || {}
        @push_to_registry = options[:push_to_registry] || false
        @registry_url = options[:registry_url]
      end

      def call
        validate_inputs
        build_image
        tag_image
        push_to_registry if @push_to_registry
      end

      private

      def validate_inputs
        raise ArgumentError, 'Image name is required' if @image_name.nil? || @image_name.empty?
        raise ArgumentError, 'Dockerfile not found' unless File.exist?(@dockerfile_path)
        if @push_to_registry && (@registry_url.nil? || @registry_url.empty?)
          raise ArgumentError, 'Registry URL is required when push_to_registry is true'
        end
      end

      def build_image
        cmd = ['docker', 'build', '-t', "#{@image_name}:#{@image_tag}", '-f', @dockerfile_path]
        @build_args.each { |k, v| cmd << "--build-arg" << "#{k}=#{v}" }
        cmd << '.'

        run_command(cmd, 'Building Docker image')
      end

      def tag_image
        return unless @push_to_registry

        full_tag = "#{@registry_url}/#{@image_name}:#{@image_tag}"
        cmd = ['docker', 'tag', "#{@image_name}:#{@image_tag}", full_tag]

        run_command(cmd, 'Tagging Docker image')
      end

      def push_to_registry
        full_tag = "#{@registry_url}/#{@image_name}:#{@image_tag}"
        cmd = ['docker', 'push', full_tag]

        run_command(cmd, 'Pushing Docker image to registry')
      end

      def run_command(cmd, description)
        logger.info("#{description}...")
        stdout, stderr, status = Open3.capture3(*cmd)
        
        if status.success?
          logger.info("#{description} completed successfully.")
          logger.debug(stdout) unless stdout.empty?
        else
          logger.error("#{description} failed.")
          logger.error(stderr)
          raise "#{description} failed: #{stderr}"
        end
      end
    end
  end
end