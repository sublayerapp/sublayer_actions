require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for scheduling events through Google Calendar API.
# This action allows integration with Google Calendar, facilitating event creation with specified
dates, times, and attendees.
#
# It is initialized with a calendar_id, event_title, start_time, end_time, and an array of
attendees (each represented as an email address). It returns the event ID of the newly created event.
#
# Example usage: Useful for AI-driven scheduling or time management features.

class CalendarEventSchedulingAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_title:, start_time:, end_time:, attendees: [])
    @calendar_id = calendar_id
    @event_title = event_title
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees.map do |email|
      { email: email }
    end
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = 'Sublayer Calendar Integration'
    @service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/calendar'])
  end

  def call
    begin
      event = create_event
      Sublayer.configuration.logger.log(:info, "Event created successfully with ID: #{event.id}")
      event.id
    rescue StandardError => e
      error_message = "Error scheduling calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @event_title,
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @start_time
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @end_time
      ),
      attendees: @attendees
    )
    @service.insert_event(@calendar_id, event)
  end
end