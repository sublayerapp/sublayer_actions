require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action allows integration with Google Calendar to automate the creation of calendar events
# based on AI-generated schedules or timelines.
#
# It is initialized with calendar_id, event_details (such as summary, location, description, start_time, and end_time).
# It returns the ID of the created Google Calendar event.
#
# Example usage: When you want to automate scheduling calendar events as part of project management workflows.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  Calendar = Google::Apis::CalendarV3

  def initialize(calendar_id:, summary:, location: nil, description: nil, start_time:, end_time:)
    @calendar_id = calendar_id
    @summary = summary
    @location = location
    @description = description
    @start_time = start_time
    @end_time = end_time
    @service = Calendar::CalendarService.new
    @service.client_options.application_name = 'Sublayer AI Integration'
    @service.authorization = Google::Auth.get_application_default([Calendar::AUTH_CALENDAR])
  end

  def call
    event = create_event
    Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{event.id}")
    event.id
  rescue Google::Apis::Error => e
    error_message = "Google API error during event creation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error creating Google Calendar event: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def create_event
    event = Calendar::Event.new(
      summary: @summary,
      location: @location,
      description: @description,
      start: Calendar::EventDateTime.new(date_time: @start_time.rfc3339),
      end: Calendar::EventDateTime.new(date_time: @end_time.rfc3339)
    )
    @service.insert_event(@calendar_id, event)
  end
end
