# Description: Sublayer::Action responsible for executing a shell command and returning the output.
#
# This action is designed to interact with the operating system, run scripts, or execute external tools.
#
# It is initialized with a command to execute.
# It returns a hash containing stdout, stderr, and the exit status of the command.
#
# Example usage: When you want to execute a system command as part of a Sublayer workflow, such as running a script or tool.

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

      Sublayer.configuration.logger.log(:info, "Executed command '#{@command}' successfully")
      result
    rescue StandardError => e
      error_message = "Error executing shell command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
