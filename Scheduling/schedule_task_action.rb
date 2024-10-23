# Description: Sublayer::Action responsible for scheduling a task to run at a future time.
# This action is useful for applications requiring delayed processing or automation of tasks.
#
# It is initialized with a task (as a Proc or lambda) and a delay in seconds.
# On execution, it schedules the task to run after the specified delay.
#
# Example usage: When you want to schedule an AI-driven process to execute later, such as sending a report.

class ScheduleTaskAction < Sublayer::Actions::Base
  def initialize(task:, delay_in_seconds:)
    @task = task
    @delay_in_seconds = delay_in_seconds
    @scheduler = Scheduler.new
  end

  def call
    begin
      Sublayer.configuration.logger.log(:info, "Scheduling task to run in \\#{@delay_in_seconds} seconds.")
      @scheduler.in(@delay_in_seconds) { execute_task }
      Sublayer.configuration.logger.log(:info, "Task scheduled successfully.")
      true
    rescue StandardError => e
      error_message = "Error scheduling task: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def execute_task
    begin
      @task.call
      Sublayer.configuration.logger.log(:info, "Task executed successfully.")
    rescue StandardError => e
      error_message = "Error executing scheduled task: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
    end
  end
end

# Note: The Scheduler class/module needs to be implemented depending on the scheduling library or solution being used.
# The `in` method should accept time in seconds and a block to execute after that time.