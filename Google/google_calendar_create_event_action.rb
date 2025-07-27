require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action allows for programmatic creation of calendar events using the Google Calendar API.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, start_time, end_time, description,
# and optional attendees list.
# It returns the ID of the created calendar event.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar events
# based on analyzed content or interactions.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [])
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @calendar_id = ENV['GOOGLE_CALENDAR_ID'] || 'primary'
    setup_client
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Calendar event created successfully with ID: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_client
    @service = Google::Apis::CalendarV3::CalendarService.new
    # Expects GOOGLE_APPLICATION_CREDENTIALS environment variable to be set
    # pointing to the JSON key file for service account
    @service.authorization = Google::Auth.get_application_default(
      ['https://www.googleapis.com/auth/calendar.events']
    )
  end

  def create_event_object
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: ENV['GOOGLE_CALENDAR_TIMEZONE'] || 'UTC'
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: ENV['GOOGLE_CALENDAR_TIMEZONE'] || 'UTC'
      }
    )

    unless @attendees.empty?
      event.attendees = @attendees.map do |email|
        Google::Apis::CalendarV3::EventAttendee.new(email: email)
      end
    end

    event
  end
end