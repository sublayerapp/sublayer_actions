module Sublayer
  module Actions
    class DataBackupToCloudAction < Base
      require 'logger'
      require 'fileutils'
      require 'dropbox_sdk' # Assuming Dropbox as the cloud storage
      
      def initialize(cloud_service:, access_token:, local_path:, remote_path:, interval: 3600)
        @cloud_service = cloud_service
        @access_token = access_token
        @local_path = local_path
        @remote_path = remote_path
        @interval = interval
        @logger = Logger.new(STDOUT)
        validate_params
      end

      def call
        loop do
          begin
            @logger.info("Starting backup...")
            upload_files(@local_path, @remote_path)
            @logger.info("Backup completed successfully.")
          rescue StandardError => e
            @logger.error("An error occurred during backup: #{e.message}")
          ensure
            @logger.info("Waiting for the next interval (#{@interval} seconds)...")
            sleep(@interval)
          end
        end
      end

      private

      def validate_params
        raise ArgumentError, "Invalid cloud service." unless @cloud_service == 'Dropbox'
        raise ArgumentError, "Local path doesn't exist." unless Dir.exist?(@local_path) || File.exist?(@local_path)
        raise ArgumentError, "Access token is required." if @access_token.nil? || @access_token.strip.empty?
      end

      def upload_files(local_path, remote_path)
        case @cloud_service
        when 'Dropbox'
          client = DropboxClient.new(@access_token)
          if File.directory?(local_path)
            Dir.glob(File.join(local_path, '**', '*')).each do |file|
              next if File.directory?(file)
              upload_file(client, file, remote_path + '/' + File.basename(file))
            end
          else
            upload_file(client, local_path, remote_path)
          end
        else
          raise NotImplementedError, "Only Dropbox is implemented for now."
        end
      end

      def upload_file(client, local_file, remote_path)
        @logger.info("Uploading #{local_file} to #{remote_path}...")
        file = open(local_file)
        response = client.put_file(remote_path, file, true)
        @logger.info("Uploaded: "+response.inspect)
      end
    end
  end
end