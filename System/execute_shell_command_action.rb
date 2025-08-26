# Description: Sublayer::Action to execute a shell command and return the stdout, stderr, and exit code.
#
# It is initialized with a command to execute.
# It returns a hash containing stdout, stderr, and exit code.
#
# Example usage: When you want to interact with system utilities or external processes from within a Sublayer workflow.

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

      Sublayer.configuration.logger.log(:info, "Executed command '#{@command}' successfully.")
      result
    rescue StandardError => e
      error_message = "Error executing shell command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
