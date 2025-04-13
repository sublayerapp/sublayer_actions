require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows AI agents to schedule meetings or create calendar events programmatically.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including start time, duration, title, description,
# and optional attendees. It returns the ID of the created calendar event.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar events
# based on conversation context or processed data.

class GoogleCalendarScheduleEventAction < Sublayer::Actions::Base
  def initialize(start_datetime:, duration_minutes:, title:, description: '', attendees: [])
    @start_datetime = start_datetime
    @duration_minutes = duration_minutes
    @title = title
    @description = description
    @attendees = attendees
    @calendar_id = 'primary' # Uses the authenticated user's primary calendar

    initialize_client
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Calendar event created successfully with ID: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_client
    @service = Google::Apis::CalendarV3::CalendarService.new
    
    # Authenticate using service account or OAuth2
    if ENV['GOOGLE_CALENDAR_CREDENTIALS_JSON']
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(ENV['GOOGLE_CALENDAR_CREDENTIALS_JSON']),
        scope: 'https://www.googleapis.com/auth/calendar'
      )
    else
      raise StandardError, 'Google Calendar credentials not found in environment'
    end

    @service.authorization = authorizer
  end

  def create_event_object
    end_time = @start_datetime + (@duration_minutes * 60)
    
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_datetime.iso8601,
        time_zone: Time.zone.name
      },
      end: {
        date_time: end_time.iso8601,
        time_zone: Time.zone.name
      }
    )

    # Add attendees if provided
    unless @attendees.empty?
      event.attendees = @attendees.map { |email| { email: email } }
    end

    event
  end
end