require 'zoom_us'

# Description: Sublayer::Action responsible for scheduling a new Zoom meeting.
#
# It is initialized with host_email, topic, start_time, duration, and participants.
# It returns the meeting_id, useful for organizing virtual meetings automatically.
#
# Example usage: When you need to schedule a recurring virtual meeting via Zoom based on AI recommendations.

class ZoomMeetingScheduleAction < Sublayer::Actions::Base
  def initialize(host_email:, topic:, start_time:, duration:, participants: [])
    @host_email = host_email
    @topic = topic
    @start_time = start_time
    @duration = duration
    @participants = participants
    @client = Zoom.new(access_token: ENV['ZOOM_ACCESS_TOKEN'])
  end

  def call
    begin
      response = @client.meeting_create(
        user_id: @host_email,
        topic: @topic,
        type: 2, # Scheduled meeting
        start_time: @start_time,
        duration: @duration,
        settings: {
          host_video: true,
          participant_video: true
        }
      )

      Sublayer.configuration.logger.log(:info, "Zoom meeting scheduled successfully with ID: #{response['id']}")
      response['id']
    rescue Zoom::Error => e
      error_message = "Error scheduling Zoom meeting: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
