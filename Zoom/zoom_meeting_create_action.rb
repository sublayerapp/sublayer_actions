require 'zoom_rb'

# Description: Sublayer::Action responsible for creating a new Zoom meeting.
# It integrates with Zoom using the zoom_rb gem.
#
# It is initialized with the topic, start_time, and optional duration and agenda.
# It returns the meeting details including join_url and meeting_id.
#
# Example usage: Automating the creation of Zoom meetings for scheduled events or AI-driven workflows.

class ZoomMeetingCreateAction < Sublayer::Actions::Base
  def initialize(topic:, start_time:, duration: 60, agenda: '')
    @topic = topic
    @start_time = start_time
    @duration = duration
    @agenda = agenda
    @client = Zoom.new(api_key: ENV['ZOOM_API_KEY'], api_secret: ENV['ZOOM_API_SECRET'])
  end

  def call
    create_meeting
  rescue Zoom::Error => e
    error_message = "Error creating Zoom meeting: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def create_meeting
    params = {
      topic: @topic,
      start_time: @start_time,
      duration: @duration,
      agenda: @agenda,
      settings: {
        host_video: true,
        participant_video: true
      }
    }

    meeting = @client.meeting_create(user_id: 'me', params: params)

    if meeting
      Sublayer.configuration.logger.log(:info, "Zoom meeting created successfully with ID: #{meeting['id']}")
      return {
        meeting_id: meeting['id'],
        join_url: meeting['join_url'],
        start_time: meeting['start_time'],
        topic: meeting['topic']
      }
    else
      raise StandardError, "Failed to create Zoom meeting"
    end
  end
end
