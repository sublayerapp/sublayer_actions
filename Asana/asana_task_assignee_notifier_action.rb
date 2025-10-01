# Description: Sublayer::Action responsible for notifying assignees in Asana when tasks are created or updated.
# It integrates with communication channels like Slack or Email to send notifications.
#
# Example usage: When you want to automatically notify task assignees in Asana about new or updated tasks, to keep them informed via their preferred communication channels.

require 'net/http'
require 'uri'
require 'json'

class AsanaTaskAssigneeNotifierAction < Sublayer::Actions::Base
  def initialize(task_gid:, communication_channel:, message:, **kwargs)
    super(**kwargs)
    @task_gid = task_gid
    @communication_channel = communication_channel
    @message = message
    @client = Asana::Client.new do |c|
      c.authentication :access_token, ENV["ASANA_ACCESS_TOKEN"]
    end
  end

  def call
    assignees = fetch_task_assignees
    send_notifications(assignees)
  end

  private

  def fetch_task_assignees
    task = @client.tasks.get_task(task_gid: @task_gid)
    task.assignee
  rescue Asana::Errors::NotFound => e
    error_message = "Error fetching task assignees: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  def send_notifications(assignees)
    assignees.each do |assignee|
      begin
        case @communication_channel.downcase
        when 'slack'
          send_slack_notification(assignee.email)
        when 'email'
          send_email_notification(assignee.email)
        else
          raise StandardError, "Unsupported communication channel: #{@communication_channel}"
        end
        Sublayer.configuration.logger.log(:info, "Notification sent to #{assignee.email}")
      rescue StandardError => e
        Sublayer.configuration.logger.log(:error, "Error sending notification to #{assignee.email}: #{e.message}")
      end
    end
  end

  def send_slack_notification(email)
    # Implementation to send Slack notification
  end

  def send_email_notification(email)
    # Implementation to send email notification
  end
end
