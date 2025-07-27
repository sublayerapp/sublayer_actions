# Description: Sublayer::Action responsible for executing a shell command and returning the standard output, standard error, and exit status.
#
# This action is initialized with a command to execute.
# It returns a hash containing the standard output (stdout), standard error (stderr), and exit status.
#
# Example usage: To run external tools or scripts and capture their output and status.

class RunShellCommandAction < Sublayer::Actions::Base
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
      error_message = "Error executing shell command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
