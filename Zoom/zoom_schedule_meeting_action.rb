require 'zoom_rb'

# Description: Sublayer::Action responsible for scheduling a Zoom meeting with specified parameters.
# This action integrates with the Zoom API to create new meetings programmatically.
#
# Requires: 'zoom_rb' gem
# $ gem install zoom_rb
# Or add `gem 'zoom_rb'` to your Gemfile
#
# It is initialized with meeting title, start time, duration (in minutes), and optional parameters
# such as description, participants, and meeting settings.
# It returns a hash containing the meeting link, ID, and other relevant details.
#
# Example usage: When you want an AI agent to automatically schedule video calls based on
# calendar analysis or meeting request processing.

class ZoomScheduleMeetingAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, duration:, description: '', participants: [], host_email: nil, settings: {})
    @title = title
    @start_time = start_time
    @duration = duration
    @description = description
    @participants = participants
    @host_email = host_email || ENV['ZOOM_DEFAULT_HOST_EMAIL']
    @settings = default_settings.merge(settings)
    
    @client = Zoom.new(
      api_key: ENV['ZOOM_API_KEY'],
      api_secret: ENV['ZOOM_API_SECRET'],
      jwt_token: ENV['ZOOM_JWT_TOKEN']
    )
  end

  def call
    begin
      meeting = create_meeting
      send_invitations(meeting) unless @participants.empty?
      
      Sublayer.configuration.logger.log(:info, "Successfully scheduled Zoom meeting: #{meeting.id}")
      
      {
        meeting_id: meeting.id,
        join_url: meeting.join_url,
        start_url: meeting.start_url,
        password: meeting.password,
        start_time: meeting.start_time,
        duration: meeting.duration
      }
    rescue Zoom::Error => e
      error_message = "Error scheduling Zoom meeting: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def default_settings
    {
      host_video: true,
      participant_video: true,
      join_before_host: false,
      mute_upon_entry: true,
      watermark: false,
      use_pmi: false,
      approval_type: 0,
      registration_type: 1,
      audio: 'both',
      auto_recording: 'none'
    }
  end

  def create_meeting
    meeting_params = {
      topic: @title,
      type: 2, # Scheduled Meeting
      start_time: @start_time.strftime('%Y-%m-%dT%H:%M:%SZ'),
      duration: @duration,
      timezone: 'UTC',
      agenda: @description,
      settings: @settings
    }

    @client.meeting_create(user_id: @host_email, params: meeting_params)
  end

  def send_invitations(meeting)
    @participants.each do |email|
      begin
        @client.meeting_registrant_create(
          meeting_id: meeting.id,
          params: {
            email: email,
            first_name: email.split('@').first,
            auto_approve: true
          }
        )
      rescue Zoom::Error => e
        Sublayer.configuration.logger.log(:warn, "Failed to send invitation to #{email}: #{e.message}")
      end
    end
  end
end