require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action allows for easy integration with Google Calendar, enabling AI agents to
# schedule meetings or create calendar events programmatically.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, description, start/end times, and attendees.
# It returns the ID of the created calendar event.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar events
# based on conversation analysis or automated workflows.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [], calendar_id: 'primary')
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @calendar_id = calendar_id
    @service = initialize_calendar_service
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Calendar event created successfully with ID: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_calendar_service
    calendar = Google::Apis::CalendarV3::CalendarService.new
    
    # Authenticate using service account or OAuth2
    if ENV['GOOGLE_CALENDAR_CREDENTIALS_JSON']
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(ENV['GOOGLE_CALENDAR_CREDENTIALS_JSON']),
        scope: 'https://www.googleapis.com/auth/calendar.events'
      )
    else
      raise StandardError, 'Google Calendar credentials not found in environment'
    end

    calendar.authorization = authorizer
    calendar
  end

  def create_event_object
    Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: format_time(@start_time),
        time_zone: Time.zone.name
      },
      end: {
        date_time: format_time(@end_time),
        time_zone: Time.zone.name
      },
      attendees: format_attendees,
      reminders: {
        use_default: true
      }
    )
  end

  def format_time(time)
    case time
    when String
      Time.parse(time).iso8601
    when Time
      time.iso8601
    else
      raise ArgumentError, 'Invalid time format. Expected String or Time object'
    end
  end

  def format_attendees
    @attendees.map { |email| { email: email } }
  end
end