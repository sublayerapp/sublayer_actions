# Description: Sublayer::Action responsible for logging detailed performance metrics of AI model executions.
# It supports analysis and optimization of Sublayer-driven processes by recording metrics such as execution time, accuracy, loss, and other relevant statistics.
# This action provides a standardized way to monitor and analyze model performance over time.
#
# Example usage: Use this action after every model training or testing run to log performance metrics and persist them for later review or analysis.

class AIModelPerformanceLoggerAction < Sublayer::Actions::Base
  require 'logger'

  def initialize(log_path:, metrics: {})
    @log_path = log_path
    @metrics = metrics
    @logger = Logger.new(@log_path)
  end

  def call
    begin
      log_performance_metrics
      Sublayer.configuration.logger.log(:info, "Successfully logged performance metrics to \\#{@log_path}")
    rescue StandardError => e
      error_message = "Error logging performance metrics: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def log_performance_metrics
    @metrics.each do |key, value|
      @logger.info("\\#{key}: \\#{value}")
    end
  end
end