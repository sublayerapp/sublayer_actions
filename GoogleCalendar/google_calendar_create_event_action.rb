require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event on Google Calendar.
# This action enables integration with Google Calendar, facilitating scheduling of events based on AI-generated tasks or deadlines.
#
# It is initialized with the calendar_id, event_title, start_time, end_time,
# and optional parameters like description and location.
# It returns the ID of the created event.
#
# Example usage: When you want to schedule a meeting or deadline in Google Calendar
# based on AI-generated inputs for better time management.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_title:, start_time:, end_time:, description: nil, location: nil)
    @calendar_id = calendar_id
    @event_title = event_title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @location = location
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])
  end

  def call
    event = create_event
    Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{event.id}")
    event.id
  rescue Google::Apis::Error => e
    error_message = "Error creating Google Calendar event: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def create_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @event_title,
      location: @location,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time, time_zone: 'UTC'),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time, time_zone: 'UTC')
    )

    @service.insert_event(@calendar_id, event)
  end
end
