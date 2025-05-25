# Description: Sublayer::Action responsible for executing a shell command and capturing its output.
#
# This action allows you to run shell commands and retrieve both standard output (stdout) and standard error (stderr).
# It also includes a timeout mechanism to prevent commands from running indefinitely.
#
# It is initialized with a command to execute and an optional timeout duration (in seconds).
# It returns a hash containing the stdout, stderr, and the exit status code of the command.
#
# Example usage: When you need to interact with the underlying operating system or execute external tools from within a Sublayer workflow.

require 'open3'
require 'timeout'

class ExecuteShellCommandAction < Sublayer::Actions::Base
  DEFAULT_TIMEOUT = 60 # seconds

  def initialize(command:, timeout: DEFAULT_TIMEOUT)
    @command = command
    @timeout = timeout
  end

  def call
    begin
      execute_command
    rescue Timeout::Error => e
      error_message = "Command \"#{@command}\" timed out after #{@timeout} seconds."
      Sublayer.configuration.logger.log(:error, error_message)
      { stdout: nil, stderr: error_message, exit_code: -1 }
    rescue StandardError => e
      error_message = "Error executing command \"#{@command}\n\": #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      { stdout: nil, stderr: error_message, exit_code: -1 }
    end
  end

  private

  def execute_command
    stdout, stderr, status = Open3.capture3(@command)

    exit_code = status.exitstatus

    Sublayer.configuration.logger.log(:info, "Command \"#{@command}\" executed with exit code #{exit_code}")

    { stdout: stdout, stderr: stderr, exit_code: exit_code }
  end
end