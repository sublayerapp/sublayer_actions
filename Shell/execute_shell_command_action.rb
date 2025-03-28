# Description: Sublayer::Action responsible for executing a shell command and returning the stdout, stderr, and exit status.
#
# This action allows for interacting with command line tools within a Sublayer workflow.
#
# It is initialized with a command to execute.
# On successful execution, it returns a hash containing stdout, stderr, and exit status.
#
# Example usage: When you want to run a system command and capture its output within an AI-driven process.

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
        exit_status: status.exitstatus
      }
      Sublayer.configuration.logger.log(:info, "Successfully executed command: #{@command}")
      result
    rescue StandardError => e
      error_message = "Error executing shell command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
