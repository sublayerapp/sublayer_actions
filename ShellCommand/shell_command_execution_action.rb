# Description: Sublayer::Action responsible for executing a shell command and returning the standard output, standard error, and exit code.
#
# This action is useful for interacting with system tools and scripts, providing a way to integrate external processes into Sublayer workflows.
#
# It is initialized with a command to execute.
# It returns a hash containing the standard output, standard error, and exit code of the command execution.
#
# Example usage: When you want to execute a system command as part of an AI workflow, such as running a data processing script or querying system information.

require 'open3'

class ShellCommand::ShellCommandExecutionAction < Sublayer::Actions::Base
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