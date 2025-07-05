# Description: Sublayer::Action to execute a shell command and return the output.
#
# This action should be used with caution due to the security risks associated with executing shell commands.
# Ensure that the command being executed is safe and does not allow for arbitrary code execution.
#
# It is initialized with a command to execute and an optional timeout in seconds.
# It returns the standard output of the command.
#
# Example usage: When you want to run a linter or formatter on a file and get the output.

require 'timeout'
require 'open3'

class ExecuteShellCommandAction < Sublayer::Actions::Base
  def initialize(command:, timeout: 60)
    @command = command
    @timeout = timeout
  end

  def call
    begin
      stdout, stderr, status = Open3.capture3(@command)

      if status.success?
        Sublayer.configuration.logger.log(:info, "Command '#{@command}' executed successfully.")
        stdout
      else
        error_message = "Command '#{@command}' failed with error: #{stderr}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue Timeout::Error => e
      error_message = "Command '#{@command}' timed out after #{@timeout} seconds."
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error executing command '#{@command}': #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end