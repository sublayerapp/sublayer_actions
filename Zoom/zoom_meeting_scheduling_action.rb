require 'zoom_sdk'

# Description: Sublayer::Action responsible for scheduling a new Zoom meeting.
# This action allows integration with Zoom to automatically schedule meetings and invite participants.
#
# It is initialized with meeting details such as topic, start_time, duration, participants, and timezone.
# It sends the meeting link to the participants upon successful scheduling.
#
# Requires: 'zoom_sdk' gem
# $ gem install zoom_sdk
# Or add `gem 'zoom_sdk'` to your Gemfile
#
# Example usage: Automate the creation of Zoom meetings for virtual workshops or team meetings based on AI-generated schedules.

class ZoomMeetingSchedulingAction < Sublayer::Actions::Base
  def initialize(topic:, start_time:, duration:, participants:, timezone: 'UTC')
    @topic = topic
    @start_time = start_time
    @duration = duration
    @participants = participants
    @timezone = timezone
    @client = Zoom::Client::OAuth.new(
      user_id: ENV['ZOOM_USER_ID'],
      client_id: ENV['ZOOM_CLIENT_ID'],
      client_secret: ENV['ZOOM_CLIENT_SECRET']
    )
  end

  def call
    meeting = create_meeting
    send_invitations(meeting)
    meeting.join_url
  rescue Zoom::Error => e
    error_message = "Error scheduling Zoom meeting: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def create_meeting
    response = @client.meeting.create(
      user_id: 'me',
      topic: @topic,
      start_time: @start_time,
      duration: @duration,
      timezone: @timezone
    )

    if response['code'] == 201
      Sublayer.configuration.logger.log(:info, "Zoom meeting scheduled successfully with ID: #{response['id']}")
      response
    else
      error_message = "Failed to schedule meeting: HTTP #{response['code']} - #{response['message']}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def send_invitations(meeting)
    invitation_message = "You are invited to a Zoom meeting.\nTopic: #{@topic}\nJoin Zoom Meeting: #{meeting.join_url}\nMeeting ID: #{meeting['id']}\n\n"
    @participants.each do |email|
      # This is a placeholder for sending an email. Actual implementation might use another service/library.
      Sublayer.configuration.logger.log(:info, "Invitation sent to #{email}")
    end
  end
end