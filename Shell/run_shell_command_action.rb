# Description: Sublayer::Action responsible for executing a shell command and returning the standard output, standard error, and exit code.
#
# It is initialized with a command to execute.
# It returns a hash containing the standard output, standard error, and exit code of the command.
#
# Example usage: When you want to run a system utility or script and capture its output for use in a Sublayer::Generator or to make decisions based on the exit code.

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
        exit_code: status.exitstatus
      }

      Sublayer.configuration.logger.log(:info, "Successfully executed shell command: #{@command}")
      result
    rescue StandardError => e
      error_message = "Error executing shell command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
