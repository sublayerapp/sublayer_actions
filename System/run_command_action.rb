# Description: Sublayer::Action responsible for running a command line command and returning the stdout, stderr, and status code.
#
# It is initialized with a command, and returns a hash containing the stdout, stderr, and status code.
#
# Example usage: When you want to run a command line command as part of a Sublayer::Generator workflow. Useful for interacting with the system or other command line tools.

class RunCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    begin
      stdout, stderr, status = Open3.capture3(@command)

      result = {
        stdout: stdout,
        stderr: stderr,
        status_code: status.exitstatus
      }

      Sublayer.configuration.logger.log(:info, "Command `#{@command}` executed successfully. Status: #{status.exitstatus}")
      result
    rescue StandardError => e
      error_message = "Error running command `#{@command}`: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
