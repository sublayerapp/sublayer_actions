# Description: Sublayer::Action responsible for executing a shell command and returning the output, exit code, and error messages.
#
# It is initialized with a command to execute.
# It returns a hash containing the output, exit code, and error messages.
#
# Example usage: When you want to execute a shell command as part of a Sublayer workflow.

class ExecuteShellCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    begin
      output, status = Open3.capture2e(@command)
      exit_code = status.exitstatus

      if exit_code == 0
        Sublayer.configuration.logger.log(:info, "Command \"#{@command}\" executed successfully.")
      else
        Sublayer.configuration.logger.log(:warn, "Command \"#{@command}\" failed with exit code #{exit_code}.")
      end

      {
        output: output,
        exit_code: exit_code,
        error_message: (exit_code != 0) ? output : nil # Standardize on error_message
      }
    rescue StandardError => e
      error_message = "Error executing shell command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end