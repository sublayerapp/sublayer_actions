require 'zoom_sdk'

# Description: Sublayer::Action responsible for scheduling a Zoom meeting.
# It automates meeting creation with specified details such as participants, time, and agenda.
#
# Initialize with host_id, participants (array of emails), start_time, duration, and agenda.
# It returns the meeting ID and join URL.
#
# Example usage: Use this action to schedule a Zoom meeting based on AI-generated analytics or notifications.

class ZoomMeetingScheduleAction < Sublayer::Actions::Base
  def initialize(host_id:, participants:, start_time:, duration:, agenda: nil)
    @host_id = host_id
    @participants = participants
    @start_time = start_time
    @duration = duration
    @agenda = agenda
    @client = ZoomSdk::Client.new(api_key: ENV['ZOOM_API_KEY'], api_secret: ENV['ZOOM_API_SECRET'])
  end

  def call
    begin
      meeting_details = create_meeting
      Sublayer.configuration.logger.log(:info, "Zoom meeting created successfully: #{meeting_details['id']}")
      { meeting_id: meeting_details['id'], join_url: meeting_details['join_url'] }
    rescue ZoomSdk::Error => e
      error_message = "Error scheduling Zoom meeting: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_meeting
    @client.meetings.create(host_id: @host_id, params: {
      topic: 'Scheduled Meeting',
      type: 2, # Scheduled meeting
      start_time: @start_time,
      duration: @duration,
      agenda: @agenda,
      settings: {
        participant_video: true,
        host_video: true
      }
    })
  end
end