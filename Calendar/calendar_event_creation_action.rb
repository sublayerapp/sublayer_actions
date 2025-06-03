require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action facilitates AI-driven scheduling and reminders by integrating with Google Calendar API.
#
# It is initialized with details like title, start_time, end_time, and optional description, location.
# It returns the ID of the created event.
#
# Example usage: Automating the creation of calendar events based on AI-generated schedules or reminders.

class CalendarEventCreationAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, location: nil)
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @location = location
    @calendar_service = initialize_google_calendar_service
  end

  def call
    begin
      event = create_event
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{event.id}")
      event.id
    rescue Google::Apis::Error => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_google_calendar_service
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CREDENTIALS_JSON']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
    calendar_service = Google::Apis::CalendarV3::CalendarService.new
    calendar_service.authorization = credentials
    calendar_service
  end

  def create_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      location: @location,
      description: @description,
      start: {
        date_time: @start_time.rfc3339
      },
      end: {
        date_time: @end_time.rfc3339
      }
    )
    @calendar_service.insert_event('primary', event)
  end
end
