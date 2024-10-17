# Description: Sublayer::Action responsible for tracking and logging the performance of various AI models over time.
# This action helps in providing insights on efficiency and improvements of models being tracked.
#
# It is initialized with the model's name, metrics, and a logging service. 
# It logs the performance metrics for analysis over time.
#
# Example usage: When you want to monitor the accuracy and speed of your AI models as they are updated or trained on new datasets.

require 'logger'

class AIModelPerformanceTrackerAction < Sublayer::Actions::Base
  def initialize(model_name:, metrics:, logging_service: Logger.new($stdout))
    @model_name = model_name
    @metrics = metrics
    @logger = logging_service
  end

  def call
    log_performance
  end

  private

  def log_performance
    begin
      @logger.info("Tracking performance for model: #{@model_name}")
      @metrics.each do |metric, value|
        @logger.info("#{metric}: #{value}")
      end
      @logger.info("Performance logging completed for model: #{@model_name}")
    rescue StandardError => e
      error_message = "Error logging performance for model #{@model_name}: #{e.message}"
      @logger.error(error_message)
      raise StandardError, error_message
    end
  end
end
