require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows scheduling of meetings or reminders based on AI-generated insights.
#
# It is initialized with a calendar_id, event_title, start_time, end_time, and optional description and attendees.
# It returns the ID of the created event.
#
# Example usage: Use this action to add new events to Google Calendar based on insights or scheduling needs.

class GoogleCalendarEventCreationAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_title:, start_time:, end_time:, description: nil, attendees: [])
    @calendar_id = calendar_id
    @event_title = event_title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @event_title,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time),
      attendees: @attendees.map { |email| { email: email } }
    )

    result = @service.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{result.id}")
    result.id
  rescue Google::Apis::Error => e
    error_message = "Error creating Google Calendar event: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end
