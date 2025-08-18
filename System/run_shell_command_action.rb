# Description: Sublayer::Action responsible for running a shell command and returning the stdout, stderr, and exit status.
#
# This action enables Sublayer to interact with the underlying operating system for tasks like system information retrieval,
# process management, or executing external tools.  It should be used with caution, as it can introduce security vulnerabilities
# if commands are not carefully validated.
#
# It is initialized with a command to execute.
# It returns a hash containing stdout, stderr, and exit status.
#
# Example usage: Get system information, run a script, or execute a command-line tool.

class RunShellCommandAction < Sublayer::Actions::Base
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

      Sublayer.configuration.logger.log(:info, "Command '#{@command}' executed successfully.")
      result
    rescue StandardError => e
      error_message = "Error executing command '#{@command}': #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end