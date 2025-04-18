# Description: Sublayer::Action responsible for executing a shell command and returning the standard output, standard error, and exit code.
#
# Example usage: When you need to run a system command and capture its output within a Sublayer workflow, such as for system monitoring or invoking external tools.

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

      Sublayer.configuration.logger.log(:info, "Successfully executed shell command: #{@command}")
      result
    rescue StandardError => e
      error_message = "Error executing shell command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
