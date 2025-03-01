# Description: Sublayer::Action responsible for executing a command line command.
# This action allows you to run shell commands and retrieve their output, which can be useful for various automation tasks.
#
# It is initialized with a command to execute.
# It returns a hash containing the stdout, stderr, and status code of the command execution.
#
# Example usage: When you want to execute a system command and use its output in a Sublayer workflow.

class ExecuteCommandLineCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    begin
      stdout, stderr, status = Open3.capture3(@command)

      result = {
        stdout: stdout,
        stderr: stderr,
        status: status.exitstatus
      }

      Sublayer.configuration.logger.log(:info, "Command '#{@command}' executed successfully. Status: #{status.exitstatus}")
      result
    rescue StandardError => e
      error_message = "Error executing command '#{@command}': #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
