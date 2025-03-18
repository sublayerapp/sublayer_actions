require 'fileutils'
require 'pg'

# Description: Sublayer::Action responsible for creating backups of database tables at regular intervals
# and storing them in a secure location for disaster recovery and data integrity purposes.
#
# It is initialized with a database connection string, a list of tables to backup, and a backup location.
# It runs the backup process and logs success or failure.
#
# Example usage: Use this action to securely backup important database tables as part of a disaster recovery plan.

class DatabaseBackupAction < Sublayer::Actions::Base
  def initialize(connection_string:, tables:, backup_location:)
    @connection_string = connection_string
    @tables = tables
    @backup_location = backup_location
    FileUtils.mkdir_p(@backup_location)
  end

  def call
    begin
      backup_tables
      Sublayer.configuration.logger.log(:info, "Database backup completed successfully.")
    rescue PG::Error => e
      error_message = "Database error during backup: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during database backup: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def backup_tables
    conn = PG.connect(@connection_string)
    @tables.each do |table|
      backup_table(conn, table)
    end
  ensure
    conn.close if conn
  end

  def backup_table(conn, table)
    timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    file_path = File.join(@backup_location, "#{table}_backup_#{timestamp}.sql")

    begin
      result = conn.exec("COPY #{table} TO STDOUT WITH (FORMAT text)")
      File.open(file_path, 'w') do |file|
        result.each_row do |row|
          file.puts row.join("\t")
        end
      end
      Sublayer.configuration.logger.log(:info, "Backup for table '#{table}' saved to #{file_path}")
    rescue PG::Error => e
      error_message = "Error backing up table '#{table}': #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
