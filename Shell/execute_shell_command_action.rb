# Description: Sublayer::Action responsible for executing a shell command and capturing the stdout, stderr, and exit code.
#
# This action is useful for running external tools or scripts and capturing their output.
#
# It is initialized with the command to execute.
# It returns a hash containing the stdout, stderr, and exit code of the command.
#
# Example usage: When you want to run a command-line tool and process its output in your Sublayer workflow.

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

      Sublayer.configuration.logger.log(:info, "Command '#{@command}' executed successfully")
      result
    rescue StandardError => e
      error_message = "Error executing command '#{@command}': #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
