require 'zoom_rb'

# Description: Sublayer::Action responsible for creating a new Zoom meeting.
# This action allows for the automated creation of Zoom meetings with specified details such as topic,
# duration, and participants. It returns the meeting ID and start URL.
#
# It is initialized with a topic, duration (in minutes), and an optional list of participant emails.
# Example usage: Automatically schedule a Zoom meeting from an AI-driven process.

class ZoomMeetingCreatorAction < Sublayer::Actions::Base
  def initialize(topic:, duration:, participants: [])
    @topic = topic
    @duration = duration
    @participants = participants
    @client = Zoom::Client::JWT.new(api_key: ENV['ZOOM_API_KEY'], api_secret: ENV['ZOOM_API_SECRET'])
  end

  def call
    begin
      response = @client.meeting_create(user_id: 'me',
                                        topic: @topic,
                                        type: 2,  # Scheduled meeting
                                        duration: @duration,
                                        settings: { join_before_host: true })
      meeting_details = {
        id: response['id'],
        start_url: response['start_url']
      }

      Sublayer.configuration.logger.log(:info, "Zoom meeting created successfully with ID: #{meeting_details[:id]}")

      schedule_participants_invite(meeting_details[:id]) if @participants.any?

      meeting_details
    rescue Zoom::Error => e
      error_message = "Error creating Zoom meeting: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def schedule_participants_invite(meeting_id)
    @participants.each do |email|
      begin
        @client.meeting_registrant_create(meeting_id: meeting_id,
                                          email: email,
                                          first_name: email.split('@').first)
        Sublayer.configuration.logger.log(:info, "Invitation sent to participant: #{email}")
      rescue Zoom::Error => e
        error_message = "Error inviting participant #{email}: #{e.message}"
        Sublayer.configuration.logger.log(:error, error_message)
      end
    end
  end
end
