# Description: Sublayer::Action responsible for executing a command line command.
# This action executes a given command line command and returns the stdout, stderr, and status.
#
# Example usage: Useful for scenarios where an AI-driven process needs to execute system commands and utilize the output.

class ExecuteCommandLineAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    execute_command
  rescue StandardError => e
    error_message = "Error executing command: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def execute_command
    stdout, stderr, status = Open3.capture3(@command)

    if status.success?
      Sublayer.configuration.logger.log(:info, "Command executed successfully: #{@command}")
    else
      Sublayer.configuration.logger.log(:error, "Command execution failed: #{stderr}")
    end

    { stdout: stdout, stderr: stderr, status: status.exitstatus }
  end
end