# Description: Sublayer::Action responsible for executing a shell command and returning the output.
# This action allows for running arbitrary shell commands and capturing their output within a Sublayer workflow.
#
# It is initialized with a command to execute.
# On successful execution, it returns the standard output of the command. If the command fails, it raises an error.
#
# Example usage: When you need to interact with the operating system or run external tools from within your Sublayer workflow.

class ExecuteShellCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    begin
      output = execute_command
      Sublayer.configuration.logger.log(:info, "Successfully executed command: \#{@command}")
      output
    rescue StandardError => e
      error_message = "Error executing command: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def execute_command
    result = Open3.capture3(@command)
    stdout = result[0]
    stderr = result[1]
    status = result[2]

    raise "Command failed: \#{stderr}" unless status.success?

    stdout
  end
end
