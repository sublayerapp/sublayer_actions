require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action allows for easy integration with Google Calendar, enabling AI-driven
# scheduling or automated task management systems.
#
# It is initialized with event details such as title, start_time, end_time, and optionally
# description and attendees.
# It returns the ID of the created event.
#
# Example usage: When you want to automatically schedule events based on AI-generated 
# insights or user interactions.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [])
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_APPLICATION_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
  end

  def call
    begin
      event = Google::Apis::CalendarV3::Event.new(
        summary: @title,
        description: @description,
        start: { date_time: @start_time.iso8601 },
        end: { date_time: @end_time.iso8601 },
        attendees: @attendees.map { |email| { email: email } }
      )

      result = @service.insert_event('primary', event)
      Sublayer.configuration.logger.log(:info, "Created event: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end