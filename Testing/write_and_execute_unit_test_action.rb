# Description: Sublayer::Action responsible for writing and executing a unit test to validate a generated code.
# The action creates a file with a test case and executes the test and returns whether the test passed or failed
#
# Example usage: To ensure that generated code meets the specified requirements.

class WriteAndExecuteUnitTestAction < Sublayer::Actions::Base
  def initialize(code_to_test:, test_code:, test_file_path:, language: 'ruby')
    @code_to_test = code_to_test
    @test_code = test_code
    @test_file_path = test_file_path
    @language = language
  end

  def call
    begin
      write_test_file
      test_result = execute_test
      Sublayer.configuration.logger.log(:info, "Test execution completed. Result: #{test_result}")
      test_result
    rescue StandardError => e
      error_message = "Error writing/executing test: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def write_test_file
    File.open(@test_file_path, 'w') do |file|
      file.write(@test_code)
    end
    Sublayer.configuration.logger.log(:info, "Test file written to #{@test_file_path}")
  end

  def execute_test
    case @language
    when 'ruby'
      execute_ruby_test
    else
      raise "Unsupported language: #{@language}"
    end
  end

  def execute_ruby_test
    result = system("ruby #{@test_file_path}")
    if result
      "Test passed"
    else
      "Test failed"
    end
  end
end
