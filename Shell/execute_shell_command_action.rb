# Description: Sublayer::Action responsible for executing a shell command and capturing its output.
# This action allows running arbitrary shell commands within a Sublayer workflow.
#
# It is initialized with a command string.
# It returns the stdout and stderr of the command.
#
# Example usage: When you want to run system utilities or scripts as part of your Sublayer workflow

class ExecuteShellCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    begin
      stdout, stderr, status = Open3.capture3(@command)

      if status.success?
        Sublayer.configuration.logger.log(:info, "Shell command executed successfully: #{@command}")
        {
          stdout: stdout,
          stderr: stderr
        }
      else
        error_message = "Shell command failed: #{@command}, stderr: #{stderr}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error executing shell command: #{e.message}")
      raise e
    end
  end
end