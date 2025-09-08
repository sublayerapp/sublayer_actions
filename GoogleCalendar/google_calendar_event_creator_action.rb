require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating a new event in Google Calendar.
# This action integrates with Google Calendar API to add events based on AI-generated schedules or reminders.
#
# It is initialized with calendar_id, event_title, start_time, end_time, and optionally, description, location, and attendees.
# It returns the ID of the created calendar event.
#
# Example usage: When you want to automatically add AI-generated meetings or reminders to your Google Calendar.

class GoogleCalendarEventCreatorAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_title:, start_time:, end_time:, description: nil, location: nil, attendees: [])
    @calendar_id = calendar_id
    @event_title = event_title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @location = location
    @attendees = attendees
    @service = initialize_calendar_service
  end

  def call
    begin
      event = create_event
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_calendar_service
    service = Google::Apis::CalendarV3::CalendarService.new
    scope = Google::Apis::CalendarV3::AUTH_CALENDAR
    service.authorization = Google::Auth.get_application_default([scope])
    service
  end

  def create_event
    Google::Apis::CalendarV3::Event.new(
      summary: @event_title,
      location: @location,
      description: @description,
      start: {
        date_time: @start_time,
        time_zone: 'UTC'
      },
      end: {
        date_time: @end_time,
        time_zone: 'UTC'
      },
      attendees: @attendees.map { |email| { email: email } },
      reminders: {
        use_default: true
      }
    )
  end
end
