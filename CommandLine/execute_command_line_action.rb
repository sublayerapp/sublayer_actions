# Description: Sublayer::Action responsible for executing a command line command and capturing its standard output,
# standard error, and exit code. This action can be useful for integrating external scripts or command line tools
# into a Sublayer workflow.
#
# It is initialized with a command to execute. It returns a hash containing stdout, stderr, and exit code.
#
# Example usage: When you need to run a system command or script as part of your AI-driven process and capture
# its output for further analysis or integration.

class ExecuteCommandLineCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    stdout, stderr, status = execute_command

    if status.success?
      Sublayer.configuration.logger.log(:info, "Command executed successfully")
    else
      error_message = "Command execution failed with status #{status.exitstatus}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    { stdout: stdout, stderr: stderr, exit_code: status.exitstatus }
  rescue StandardError => e
    error_message = "Error executing command: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def execute_command
    require 'open3'
    stdout, stderr, status = Open3.capture3(@command)
    [stdout, stderr, status]
  end
end
