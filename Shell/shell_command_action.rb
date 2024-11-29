class ShellCommandAction < Sublayer::Actions::Base
  def initialize(command:, timeout: 60)
    @command = command
    @timeout = timeout
  end

  def call
    begin
      output = Timeout::timeout(@timeout) do
        `#{@command}`
      end

      Sublayer.configuration.logger.log(:info, "Shell command executed successfully: #{@command}")
      output
    rescue Timeout::Error
      error_message = "Shell command execution timed out after #{@timeout} seconds: #{@command}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise Timeout::Error, error_message
    rescue StandardError => e
      error_message = "Error executing shell command: #{@command} - #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end