# Description: Sublayer::Action responsible for executing a shell command and capturing its output (stdout and stderr).
# This action is useful for running external tools or scripts within a Sublayer workflow and using their results.
#
# Example usage: When you want to run a command-line tool and use its output in a subsequent step of your Sublayer workflow.

class ExecuteShellCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    begin
      stdout, stderr, status = Open3.capture3(@command)

      if status.success?
        Sublayer.configuration.logger.log(:info, "Command `\#{@command}` executed successfully.")
        { stdout: stdout, stderr: stderr, exit_code: status.exitstatus }
      else
        error_message = "Command `\#{@command}` failed with exit code \#{status.exitstatus}. Stderr: \#{stderr}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error executing shell command: \#{e.message}")
      raise e
    end
  end
end
