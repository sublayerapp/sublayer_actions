require 'open3'

# Description: Sublayer::Action responsible for evaluating a Ruby code snippet in a sandbox environment.
# This action is useful for agents that can debug and test their own generated code by providing stdout, stderr, and status.
#
# It is initialized with a code snippet.
# It returns a hash containing the stdout, stderr, and status of the code execution.
#
# Example usage: When you want to test a generated code snippet to ensure it functions as expected.

class EvaluateCodeAction < Sublayer::Actions::Base
  def initialize(code:)
    @code = code
  end

  def call
    execute_code
  rescue StandardError => e
    error_message = "Error evaluating code: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def execute_code
    stdout, stderr, status = Open3.capture3("ruby -e '#{@code}'")

    result = {
      stdout: stdout,
      stderr: stderr,
      status: status.exitstatus
    }

    Sublayer.configuration.logger.log(:info, "Code evaluated successfully. Status: #{status.exitstatus}")
    result
  end
end
