# Description: Sublayer::Action responsible for creating a backup of a specified database and storing it in a cloud storage solution.
#
# This action is useful for ensuring data security and integrity in automated workflows.

require 'aws-sdk-s3'
require 'logger'

class DatabaseBackupAction < Sublayer::Actions::Base
  def initialize(database_url:, bucket_name:, object_key:, aws_access_key_id: nil, aws_secret_access_key: nil)
    @database_url = database_url
    @bucket_name = bucket_name
    @object_key = object_key
    @s3_client = Aws::S3::Client.new(
      access_key_id: aws_access_key_id || ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: aws_secret_access_key || ENV['AWS_SECRET_ACCESS_KEY']
    )
    @logger = Logger.new($stdout)
  end

  def call
    begin
      backup_file_path = create_database_backup
      upload_to_s3(backup_file_path)
    rescue StandardError => e
      @logger.error "Error in DatabaseBackupAction: #{e.message}"
      raise e
    ensure
      cleanup(backup_file_path) if backup_file_path && File.exist?(backup_file_path)
    end
  end

  private

  def create_database_backup
    # Implement logic to create a database backup
    # This method should return the path to the backup file
    # Example placeholder logic - replace with actual backup logic
    backup_file_path = "/tmp/backup.sql"
    `pg_dump #{@database_url} > #{backup_file_path}`
    backup_file_path
  end

  def upload_to_s3(file_path)
    @s3_client.put_object(
      bucket: @bucket_name,
      key: @object_key,
      body: File.open(file_path)
    )
    @logger.info "Successfully uploaded backup to S3: #{@bucket_name}/#{@object_key}"
  end

  def cleanup(file_path)
    File.delete(file_path)
    @logger.info "Deleted local backup file: #{file_path}"
  end
end
