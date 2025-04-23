require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action allows for easy automation of Google Calendar events based on user specifications.
#
# It is initialized with calendar_id, summary, start_time, end_time, and optional description and attendees.
# It returns the id of the created event.
#
# Example usage: When you want to create a calendar event based on LLM recommendations or schedule AI-driven processes.

class GoogleCalendarEventCreationAction < Sublayer::Actions::Base
  def initialize(calendar_id:, summary:, start_time:, end_time:, description: nil, attendees: [])
    @calendar_id = calendar_id
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees.map { |email| { email: email } }
    @service = initialize_google_calendar_service
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      start: { date_time: @start_time.to_datetime.rfc3339 },
      end: { date_time: @end_time.to_datetime.rfc3339 },
      attendees: @attendees
    )

    begin
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Google Calendar event created successfully: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_google_calendar_service
    service = Google::Apis::CalendarV3::CalendarService.new
    service.client_options.application_name = 'Sublayer AI Application'
    service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])
    service
  end
end