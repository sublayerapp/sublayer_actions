# Description: Sublayer::Action responsible for executing a command line command and returning its output.
# This action provides a safe and controlled way to execute shell commands and capture their results.
#
# It is initialized with a command to execute, and returns a hash containing:
# - stdout: The standard output from the command
# - stderr: The standard error output from the command
# - exit_code: The command's exit status code
#
# Example usage: When you want to execute system commands as part of an AI workflow,
# such as running git commands, processing files, or interacting with system utilities.

class ExecuteCommandLineCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    begin
      Sublayer.configuration.logger.log(:info, "Executing command: #{@command}")
      
      # Create temporary files for capturing output
      stdout_file = Tempfile.new('stdout')
      stderr_file = Tempfile.new('stderr')

      # Execute the command and capture output
      pid = spawn(@command, out: stdout_file.path, err: stderr_file.path)
      Process.waitpid(pid)
      exit_code = $?.exitstatus

      # Read the output
      stdout = File.read(stdout_file.path)
      stderr = File.read(stderr_file.path)

      Sublayer.configuration.logger.log(:info, "Command completed with exit code: #{exit_code}")

      {
        stdout: stdout,
        stderr: stderr,
        exit_code: exit_code
      }
    rescue StandardError => e
      error_message = "Error executing command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      # Clean up temporary files
      stdout_file&.close
      stderr_file&.close
      stdout_file&.unlink
      stderr_file&.unlink
    end
  end
end