require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action is useful for automating meeting setups and reminders based on AI-generated inputs or team scheduling needs.
#
# It is initialized with a calendar_id, event_title, start_time, end_time, and optional description and location.
# It returns the ID of the created event.
#
# Example usage: When you want to create a calendar event automatically based on AI suggestions or schedule inputs from a team.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  def initialize(calendar_id:, event_title:, start_time:, end_time:, description: '', location: '')
    @calendar_id = calendar_id
    @event_title = event_title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @location = location
    @service = initialize_service
  end

  def call
    create_event
  rescue Google::Apis::ClientError => e
    error_message = "Google Calendar API error during event creation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error creating Google Calendar event: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def initialize_service
    service = Google::Apis::CalendarV3::CalendarService.new
    service.client_options.application_name = 'Sublayer Google Calendar Integration'
    service.authorization = Google::Auth.get_application_default([SCOPE])
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

    result = @service.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{result.id}")
    result.id
  end
end
