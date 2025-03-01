# Description: Sublayer::Action responsible for executing a shell command and returning the output (stdout and stderr) and exit status.
#
# It is initialized with the command to execute.
# It returns a hash containing the stdout, stderr, and exit status of the command.
#
# Example usage: When you want to interact with the underlying operating system or run command-line tools.

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
        exit_status: status.exitstatus
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
