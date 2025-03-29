# Description: Sublayer::Action responsible for executing a shell command and capturing its output (stdout, stderr, exit code).
# Useful for interacting with the OS, running scripts, or calling external tools.
#
# It is initialized with the command to execute and optionally a timeout value.
# It returns a hash containing the stdout, stderr, and exit code of the command.
#
# Example usage: When you want to run a system command and use its output in a Sublayer::Generator.

require 'open3'
require 'timeout'

class ExecuteShellCommandAction < Sublayer::Actions::Base
  def initialize(command:, timeout: 60) # Timeout in seconds
    @command = command
    @timeout = timeout
  end

  def call
    begin
      stdout, stderr, status = Open3.capture3(@command)
      exit_code = status.exitstatus

      Sublayer.configuration.logger.log(:info, "Command \"#{@command}\" executed successfully.")

      {
        stdout: stdout,
        stderr: stderr,
        exit_code: exit_code
      }
    rescue Timeout::Error => e
      error_message = "Command \"#{@command}\" timed out after #{@timeout} seconds."
      Sublayer.configuration.logger.log(:error, error_message)
      {
        stdout: nil,
        stderr: error_message,
        exit_code: 124 # Standard exit code for timeout
      }

    rescue StandardError => e
      error_message = "Error executing command \"#{@command}\": #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      {
        stdout: nil,
        stderr: error_message,
        exit_code: 1 # Generic error code
      }
    end
  end
end