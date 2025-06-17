# Description: Sublayer::Action responsible for executing a shell command and returning the standard output, standard error, and exit code.
#
# Example usage: When you need to run a system command and capture its output for further processing within a Sublayer workflow.
#
# Initialized with the command to execute.
# Returns a hash containing :stdout, :stderr, and :exit_code.

class ExecuteShellCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    begin
      stdout, stderr, status = Open3.capture3(@command)

      result = {
        stdout: stdout,
        stderr: stderr,
        exit_code: status.exitstatus
      }

      Sublayer.configuration.logger.log(:info, "Executed command: #{@command}")
      result
    rescue StandardError => e
      error_message = "Error executing command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
