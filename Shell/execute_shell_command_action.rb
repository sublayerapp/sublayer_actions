# Description: Sublayer::Action responsible for executing a shell command and returning the standard output, standard error, and exit code.
#
# It is initialized with the command to execute.
# It returns a hash containing the standard output, standard error, and exit code.
#
# Example usage: When you want to run command-line tools or scripts as part of a Sublayer workflow.

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

      Sublayer.configuration.logger.log(:info, "Executed command `#{@command}` successfully")
      result
    rescue StandardError => e
      error_message = "Error executing command `#{@command}`: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
