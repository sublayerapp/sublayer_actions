# Description: Sublayer::Action responsible for executing a shell command and capturing its output.
# This action allows running arbitrary shell commands within a Sublayer workflow,
# which can be useful for tasks such as scripting, data processing, or system administration.
#
# It is initialized with a command (a string) and optional arguments.
# It returns the standard output of the command. If the command fails, raises a StandardError
#
# Example usage: Running a data processing script and sending the result to an LLM

class ExecuteShellCommandAction < Sublayer::Actions::Base
  def initialize(command:, arguments: [])
    @command = command
    @arguments = arguments
  end

  def call
    begin
      output = `#{@command} #{@arguments.join(' ')} 2>&1`
      exit_status = $?.exitstatus

      if exit_status == 0
        Sublayer.configuration.logger.log(:info, "Shell command '#{@command}' executed successfully.")
        output
      else
        error_message = "Shell command '#{@command}' failed with exit status #{exit_status}: #{output}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error executing shell command: #{e.message}")
      raise e
    end
  end
end