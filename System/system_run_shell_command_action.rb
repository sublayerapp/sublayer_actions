# Description: Sublayer::Action responsible for running a shell command and capturing its output, error, and exit code.
#
# This action provides a way for Sublayer workflows to interact with external processes and retrieve their results.
#
# It is initialized with a command to execute. It returns a hash containing the standard output, standard error, and exit code of the command.
#
# Example usage: When you want to execute a system command as part of your Sublayer workflow, such as running a script or interacting with a command-line tool.

class SystemRunShellCommandAction < Sublayer::Actions::Base
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
