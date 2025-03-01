# Description: Sublayer::Action responsible for executing a command line command and returning the standard output, standard error, and exit code.
#
# This action can be useful for automating tasks or integrating with external tools.
#
# It is initialized with the command to execute.
# It returns a hash containing the standard output, standard error, and exit code.
#
# Example usage: When you want to execute a shell command and capture its output within a Sublayer workflow.

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
        exit_code: status.exitstatus
      }

      Sublayer.configuration.logger.log(:info, "Command '#{@command}' executed successfully. Exit code: #{status.exitstatus}")
      result
    rescue StandardError => e
      error_message = "Error executing command '#{@command}': #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
