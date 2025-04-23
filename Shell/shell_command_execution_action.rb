require 'open3'

# Description: Sublayer::Action responsible for executing a shell command and returning the output.
# This action allows integration with arbitrary command-line tools.
#
# It is initialized with the command to execute.
# It returns the standard output of the command.
#
# Example usage: When you want to run a system command and use the output in your Sublayer workflow.

class ShellCommandExecutionAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    begin
      stdout, stderr, status = Open3.capture3(@command)

      if status.success?
        Sublayer.configuration.logger.log(:info, "Command '#{@command}' executed successfully")
        stdout
      else
        error_message = "Command '#{@command}' failed with error: #{stderr}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      error_message = "Error executing shell command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
