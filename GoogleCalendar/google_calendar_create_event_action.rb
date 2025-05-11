require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action interfaces with Google Calendar API to schedule events based on time suggestions or deadlines from AI,
# enhancing calendar management capabilities within workflows.
#
# It is initialized with a calendar_id, event_title, start_time, end_time, and optionally description and location.
# It returns the ID of the created event for verification.
#
# Example usage: When you want to create a calendar event to schedule meetings or reminders as suggested by an AI process.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_title:, start_time:, end_time:, description: nil, location: nil)
    @calendar_id = calendar_id
    @event_title = event_title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @location = location
    @service = initialize_service
  end

  def call
    begin
      event = create_event
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{event.id}")
      event.id
    rescue Google::Apis::ClientError => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_service
    service = Google::Apis::CalendarV3::CalendarService.new
    service.client_options.application_name = 'Sublayer'
    service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/calendar'])
    service
  end

  def create_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @event_title,
      location: @location,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time)
    )

    @service.insert_event(@calendar_id, event)
  end
end
