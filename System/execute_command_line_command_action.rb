# Description: Sublayer::Action responsible for executing a command line command and returning its output.
# This action provides a safe way to execute shell commands and capture their results.
#
# It is initialized with a command to execute and returns a hash containing stdout, stderr, and exit status.
#
# Example usage: When you want to run system commands as part of an AI workflow, such as running git commands,
# executing scripts, or performing system operations.
#
# Security note: Be careful when using this action with untrusted input to avoid command injection vulnerabilities.

class ExecuteCommandLineCommandAction < Sublayer::Actions::Base
  def initialize(command:, timeout: 30)
    @command = command
    @timeout = timeout # Maximum time in seconds to wait for command completion
  end

  def call
    begin
      Sublayer.configuration.logger.log(:info, "Executing command: #{@command}")
      
      # Use Open3 to capture both stdout and stderr
      stdout, stderr, status = execute_with_timeout
      
      result = {
        stdout: stdout.strip,
        stderr: stderr.strip,
        status: status.exitstatus
      }
      
      if status.success?
        Sublayer.configuration.logger.log(:info, "Command executed successfully with status: #{status.exitstatus}")
      else
        Sublayer.configuration.logger.log(:warn, "Command execution failed with status: #{status.exitstatus}")
      end
      
      result
    rescue Timeout::Error => e
      error_message = "Command execution timed out after #{@timeout} seconds"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error executing command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def execute_with_timeout
    require 'timeout'
    require 'open3'

    Timeout.timeout(@timeout) do
      Open3.capture3(@command)
    end
  end
end