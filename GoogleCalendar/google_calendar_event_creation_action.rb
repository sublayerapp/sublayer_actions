require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action integrates with Google Calendar using the Google Calendar API.
#
# It is initialized with a calendar_id, title, start_time, end_time, and optionally location and invitees.
# It returns the ID of the created event.
#
# Example usage: When you want to create a calendar event based on AI-generated scheduling or reminders.

class GoogleCalendarEventCreationAction < Sublayer::Actions::Base
  def initialize(calendar_id:, title:, start_time:, end_time:, location: nil, invitees: [])
    @calendar_id = calendar_id
    @title = title
    @start_time = start_time
    @end_time = end_time
    @location = location
    @invitees = invitees
    @service = initialize_service
  end

  def call
    create_event
  rescue Google::Apis::Error => e
    error_message = "Error creating Google Calendar event: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
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
      summary: @title,
      location: @location,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time.rfc3339),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time.rfc3339)
    )

    unless @invitees.empty?
      event.attendees = @invitees.map { |email| Google::Apis::CalendarV3::EventAttendee.new(email: email) }
    end

    result = @service.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{result.id}")
    result.id
  end
end