# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action facilitates scheduling meetings or reminders directly from workflows.
#
# It is initialized with parameters such as summary, start_time, end_time, attendees, and optional description and location.
# It returns the ID of the created event to confirm successful creation.
#
# Example usage: When you want to automate the scheduling of meetings or reminders based on AI-generated insights or processes.

require 'google/apis/calendar_v3'
require 'googleauth'

class GoogleCalendarEventCreationAction < Sublayer::Actions::Base
  def initialize(summary:, start_time:, end_time:, attendees: [], description: nil, location: nil)
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @description = description
    @location = location
    @calendar_service = initialize_calendar_service
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      location: @location,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @start_time,
        time_zone: 'Etc/UTC'
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @end_time,
        time_zone: 'Etc/UTC'
      ),
      attendees: @attendees.map { |email| { email: email } }
    )

    result = @calendar_service.insert_event('primary', event)
    Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{result.id}")
    result.id
  rescue Google::Apis::Error => e
    error_message = "Google Calendar API error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error creating Google Calendar event: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def initialize_calendar_service
    scope = 'https://www.googleapis.com/auth/calendar'
    authorization = Google::Auth.get_application_default([scope])
    calendar_service = Google::Apis::CalendarV3::CalendarService.new
    calendar_service.authorization = authorization
    calendar_service
  end
end
