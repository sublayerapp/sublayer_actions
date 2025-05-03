# Description: Sublayer::Action responsible for executing a shell command and returning the standard output, standard error, and exit code.
#
# This action is initialized with a command to execute. It returns a hash containing the standard output, standard error, and exit code.
#
# Example usage: When you want to interact with system utilities or run custom scripts from within a Sublayer workflow.

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

      Sublayer.configuration.logger.log(:info, "Executed command \"#{@command}\" successfully. Exit code: #{status.exitstatus}")
      result
    rescue StandardError => e
      error_message = "Error executing shell command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
