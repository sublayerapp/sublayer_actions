# Description: Sublayer::Action responsible for executing a shell command and returning the standard output, standard error, and exit code.
# Useful for interacting with system utilities or external tools.
#
# Example usage:
# 1. Checking system status (e.g., disk space, CPU usage).
# 2. Running command-line tools (e.g., `ls`, `grep`, `awk`).
# 3. Interacting with external scripts.

class ExecuteShellCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    begin
      stdout, stderr, status = Open3.capture3(@command)

      result = {
        stdout: stdout,
        stderr: stderr,
        exit_code: status.exitstatus
      }

      if status.success?
        Sublayer.configuration.logger.log(:info, "Command `#{@command}` executed successfully.")
      else
        Sublayer.configuration.logger.log(:warn, "Command `#{@command}` failed with exit code #{status.exitstatus}.")
      end

      result
    rescue StandardError => e
      error_message = "Error executing shell command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
