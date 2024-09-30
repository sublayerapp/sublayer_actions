require 'sublayer/actions/base'

module Sublayer
  module Actions
    class ExecuteShellCommandAction < Sublayer::Actions::Base
      def initialize(command:)
        @command = command
      end

      def call
        stdout, stderr, status = Open3.capture3(@command)

        if status.success?
          logger.info "Command '#{@command}' executed successfully." 
          logger.debug "Output: #{stdout}"
        else
          message = "Command '#{@command}' failed with exit status #{status.exitstatus}."
          logger.error message
          logger.error "Error output: #{stderr}"
          raise message
        end

        Output.new(stdout: stdout, stderr: stderr, exit_status: status.exitstatus)
      rescue StandardError => e
        logger.error "An error occurred while executing command '#{@command}': #{e.message}"
        raise
      end

      class Output < Sublayer::Output
        attr_reader :stdout, :stderr, :exit_status

        def initialize(stdout:, stderr:, exit_status:)
          @stdout = stdout
          @stderr = stderr
          @exit_status = exit_status
        end
      end
    end
  end
end