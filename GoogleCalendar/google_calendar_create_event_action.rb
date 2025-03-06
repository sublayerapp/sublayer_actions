require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action allows for easy integration with Google Calendar for scheduling meetings
# or creating reminders based on AI-generated insights or automated processes.
#
# Requires:
# - google-api-client gem
# - Set up Google Calendar API and obtain credentials
# - Store credentials in GOOGLE_CALENDAR_CREDENTIALS env variable (JSON format)
#
# It is initialized with event details including title, start_time, end_time,
# description (optional), and attendees (optional).
# Returns the ID of the created event.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar
# events based on analysis or generated content.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [])
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @calendar_id = 'primary' # Uses the authenticated user's primary calendar

    setup_client
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Created Google Calendar event: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_client
    @service = Google::Apis::CalendarV3::CalendarService.new
    
    # Load credentials from environment variable
    credentials = JSON.parse(ENV['GOOGLE_CALENDAR_CREDENTIALS'])
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(credentials.to_json),
      scope: 'https://www.googleapis.com/auth/calendar'
    )
    
    @service.authorization = authorizer
  end

  def create_event_object
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: 'UTC'
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: 'UTC'
      }
    )

    # Add attendees if provided
    unless @attendees.empty?
      event.attendees = @attendees.map { |email| { email: email } }
    end

    event
  end
end