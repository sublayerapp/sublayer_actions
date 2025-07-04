require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating a new event in Google Calendar.
# This action integrates with Google Calendar using the Google Calendar API.
# It is initialized with the title, description, start time, end time, and attendees, and creates the event accordingly.
#
# Example usage: When you want to schedule a meeting directly through an AI workflow by creating a new event in Google Calendar.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, description:, start_time:, end_time:, attendees: [])
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees.map { |email| { email: email } }
    @calendar_service = Google::Apis::CalendarV3::CalendarService.new
    @calendar_service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])  
  end

  def call
    begin
      event = create_event
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{event.id}")
      event
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def create_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time, time_zone: 'UTC'),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time, time_zone: 'UTC'),
      attendees: @attendees
    )
    @calendar_service.insert_event('primary', event)
  end
end