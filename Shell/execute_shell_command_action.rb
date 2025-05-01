# Description: Sublayer::Action responsible for executing a shell command and returning the standard output, standard error, and exit code.
#
# Example usage: When you want to execute a shell command as part of a Sublayer workflow, such as running a script or executing a system command.

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

      Sublayer.configuration.logger.log(:info, "Successfully executed command: #{@command}")
      result
    rescue StandardError => e
      error_message = "Error executing command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
