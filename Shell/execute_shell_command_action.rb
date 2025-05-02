# Description: Sublayer::Action responsible for executing a shell command and returning the standard output, standard error, and exit code.
#
# This action allows you to run arbitrary shell commands from within a Sublayer workflow.  Be extremely careful when using this, as it can be very dangerous.
#
# It is initialized with the command to execute.
# It returns a hash containing the standard output, standard error, and exit code of the command.
#
# Example usage: When you want to execute a shell command as part of an automated workflow.

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

      Sublayer.configuration.logger.log(:info, "Executed shell command: #{@command}")
      result
    rescue StandardError => e
      error_message = "Error executing shell command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end