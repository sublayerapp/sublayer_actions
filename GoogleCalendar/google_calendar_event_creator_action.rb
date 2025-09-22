require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows for creating calendar events based on project deadlines or meeting requests.
#
# It is initialized with calendar_id, summary, start_time, end_time, and optional description,
# attendees, and location.
# It returns the ID of the created event.
#
# Example usage: When you need to automatically schedule meetings or deadlines in Google Calendar
# based on data from Slack channels, GitHub issues, etc.

class GoogleCalendarEventCreatorAction < Sublayer::Actions::Base
  Calendar = Google::Apis::CalendarV3

  def initialize(calendar_id:, summary:, start_time:, end_time:, description: nil, attendees: [], location: nil)
    @calendar_id = calendar_id
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees.map { |email| { email: email } }
    @location = location
    @service = Calendar::CalendarService.new
    @service.client_options.application_name = "Sublayer App"
    @service.authorization = Google::Auth.get_application_default([Calendar::AUTH_CALENDAR])
  end

  def call
    begin
      event = create_event
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar. Event ID: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_event
    Calendar::Event.new(
      summary: @summary,
      location: @location,
      description: @description,
      start: Calendar::EventDateTime.new(
        date_time: @start_time.iso8601
      ),
      end: Calendar::EventDateTime.new(
        date_time: @end_time.iso8601
      ),
      attendees: @attendees
    )
  end
end
