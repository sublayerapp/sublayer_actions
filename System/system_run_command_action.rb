# Description: Sublayer::Action responsible for running a shell command and returning the standard output, standard error, and exit code.
#
# It is initialized with a command to execute.
# It returns a hash containing the standard output (stdout), standard error (stderr), and the exit code.
#
# Example usage: When you want to execute a system command as part of an automated workflow, such as running a script or interacting with the operating system.

require 'open3'

class SystemRunCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    stdout, stderr, status = Open3.capture3(@command)

    result = {
      stdout: stdout,
      stderr: stderr,
      exit_code: status.exitstatus
    }

    if status.success?
      Sublayer.configuration.logger.log(:info, "Command `#{@command}` executed successfully. Exit code: #{status.exitstatus}")
    else
      Sublayer.configuration.logger.log(:error, "Command `#{@command}` failed. Exit code: #{status.exitstatus}, Error: #{stderr}")
    end

    result
  rescue StandardError => e
    error_message = "Error running command `#{@command}`: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end
