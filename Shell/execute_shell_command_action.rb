# Description: Sublayer::Action responsible for executing a shell command and returning the output.
# This action allows for running arbitrary shell commands within a Sublayer workflow,
# enabling integration with external tools and scripts.
#
# It is initialized with a command string.
# It returns the standard output of the executed command as a string
# or raises an error upon failure.
#
# Example usage: When you want to run shell commands or scripts within your Sublayer workflow.

class ExecuteShellCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    begin
      output = `#{@command}`
      exit_status = $?.exitstatus

      if exit_status == 0
        Sublayer.configuration.logger.log(:info, "Shell command '#{@command}' executed successfully.")
        output
      else
        error_message = "Shell command '#{@command}' failed with exit status #{exit_status}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error executing shell command: #{e.message}")
      raise e
    end
  end
end