require "google/apis/calendar_v3"
require "googleauth"

# Description: Sublayer::Action to create events in a user's Google Calendar.
# This action provides integration with Google Calendar to automate
# event scheduling and reminders within workflows.
#
# Requires: 'google-api-client' gem
# $ gem install google-api-client
#
# It is initialized with a calendar_id, event_details,
# including start_time, end_time, summary, description, and attendees.
# Returns the event id upon successful creation.
#
# Example usage: When you want to automatically schedule meetings or reminders as part of an AI-driven process.

class GoogleCalendarEventCreationAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_details: {})
    @calendar_id = calendar_id
    @event_details = event_details
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @event_details[:summary],
      description: @event_details[:description],
      start: {
        date_time: @event_details[:start_time],
        time_zone: @event_details[:time_zone] || "UTC",
      },
      end: {
        date_time: @event_details[:end_time],
        time_zone: @event_details[:time_zone] || "UTC",
      },
      attendees: @event_details[:attendees].map { |email| { email: email } }
    )

    begin
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating event in Google Calendar: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
