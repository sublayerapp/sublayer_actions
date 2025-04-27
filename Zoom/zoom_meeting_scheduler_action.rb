require 'zoom'

# Description: Sublayer::Action responsible for scheduling a Zoom meeting.
# This action is intended to be used for automatically arranging meetings as part of workflows based on AI outputs.
#
# It is initialized with a host, topic, start_time, duration, and optional additional settings.
# It returns the join URL for the scheduled meeting.
#
# Example usage: When you want to schedule a meeting with LLM output or as part of an AI-driven process.

class ZoomMeetingSchedulerAction < Sublayer::Actions::Base
  def initialize(host:, topic:, start_time:, duration:, settings: {})
    @host = host
    @topic = topic
    @start_time = start_time
    @duration = duration
    @settings = settings
    @client = Zoom::Client::OAuth.new(access_token: ENV['ZOOM_ACCESS_TOKEN'])
  end

  def call
    begin
      response = @client.meeting_create(
        user_id: @host,
        topic: @topic,
        start_time: @start_time,
        duration: @duration,
        settings: @settings
      )
      meeting_url = response.dig('join_url')
      Sublayer.configuration.logger.log(:info, "Meeting scheduled successfully: #{meeting_url}")
      meeting_url
    rescue Zoom::Error => e
      error_message = "Error scheduling Zoom meeting: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
