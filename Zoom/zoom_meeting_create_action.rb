require 'zoom_rb'

# Description: Sublayer::Action responsible for creating Zoom meetings programmatically.
# This action integrates with the Zoom API to schedule video conference meetings.
#
# Requires: 'zoom_rb' gem
# $ gem install zoom_rb
# Or add `gem 'zoom_rb'` to your Gemfile
#
# It is initialized with meeting details including title, start_time, duration, and participants.
# It returns a hash containing the meeting details including join URL and meeting ID.
#
# Example usage: When you want an AI agent to schedule video calls as part of a meeting
# coordination workflow, integrating with calendar and notification systems.

class ZoomMeetingCreateAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, duration_minutes:, participants:, host_email: nil)
    @title = title
    @start_time = start_time # Expected as DateTime or Time object
    @duration_minutes = duration_minutes
    @participants = participants # Array of email addresses
    @host_email = host_email || ENV['ZOOM_DEFAULT_HOST_EMAIL']
    
    @client = Zoom.new(
      api_key: ENV['ZOOM_API_KEY'],
      api_secret: ENV['ZOOM_API_SECRET'],
      timeout: 15
    )
  end

  def call
    begin
      meeting = create_meeting
      send_invitations(meeting)
      
      Sublayer.configuration.logger.log(:info, "Created Zoom meeting: #{meeting[:join_url]}")
      
      {
        id: meeting[:id],
        join_url: meeting[:join_url],
        start_url: meeting[:start_url],
        password: meeting[:password],
        start_time: meeting[:start_time],
        duration: meeting[:duration]
      }
    rescue Zoom::Error => e
      error_message = "Failed to create Zoom meeting: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_meeting
    meeting_options = {
      topic: @title,
      type: 2, # Scheduled meeting
      start_time: @start_time.strftime('%Y-%m-%dT%H:%M:%SZ'),
      duration: @duration_minutes,
      timezone: 'UTC',
      settings: {
        host_video: true,
        participant_video: true,
        join_before_host: false,
        mute_upon_entry: true,
        waiting_room: true,
        meeting_authentication: true
      }
    }

    @client.meeting_create(user_id: @host_email, options: meeting_options)
  end

  def send_invitations(meeting)
    @participants.each do |email|
      begin
        @client.meeting_invitation_send(
          meeting_id: meeting[:id],
          email: email
        )
      rescue Zoom::Error => e
        Sublayer.configuration.logger.log(:warn, "Failed to send invitation to #{email}: #{e.message}")
      end
    end
  end
end