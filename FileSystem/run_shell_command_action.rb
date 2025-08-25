# Description: Sublayer::Action to execute a shell command and return the output and exit code.
#
# It is initialized with the command to execute.
# It returns a hash containing the output (stdout and stderr) and the exit code.
#
# Example usage:
#  action = RunShellCommandAction.new(command: "ls -l")
#  result = action.call
#  puts result[:output] #=> (stdout + stderr) combined
#  puts result[:exit_code] #=> 0 if successful

class RunShellCommandAction < Sublayer::Actions::Base
  def initialize(command:)
    @command = command
  end

  def call
    output = nil
    exit_code = nil
    begin
      output = `"#{@command}" 2>&1` # Redirect stderr to stdout
      exit_code = $?.exitstatus

      if exit_code == 0
        Sublayer.configuration.logger.log(:info, "Command '#{@command}' executed successfully.")
      else
        Sublayer.configuration.logger.log(:warn, "Command '#{@command}' failed with exit code #{exit_code}.")
      end

      { output: output, exit_code: exit_code }
    rescue StandardError => e
      error_message = "Error executing command '#{@command}': #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end