# Description: Sublayer::Action responsible for executing a shell command and returning the output.
#
# This action enables interaction with system tools and processes, making it useful for tasks like running scripts or interacting with external services.
#
# It is initialized with a command to execute.
# It returns the standard output of the command.
#
# Example usage: When you want to run a system command and use the output in your Sublayer workflow.

class ExecuteShellCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    begin
      output = execute_command
      Sublayer.configuration.logger.log(:info, "Successfully executed command: #{@command}")
      output
    rescue StandardError => e
      error_message = "Error executing command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def execute_command
    `#{@command}`
  end
end
