require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action allows for programmatic creation of calendar events, which is useful
# for AI agents that need to schedule meetings or follow-ups.
#
# Requires: 'google-api-client' gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# Required environment variables:
# - GOOGLE_CALENDAR_CREDENTIALS: Path to the Google Calendar API credentials JSON file
#
# It is initialized with event details including title, start_time, end_time,
# description (optional), and attendees (optional).
# It returns the created event object's ID.
#
# Example usage: When an AI agent needs to schedule a follow-up meeting based on
# conversation analysis or task completion requirements.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [])
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @calendar_id = 'primary'  # Uses the authenticated user's primary calendar

    initialize_calendar_service
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(
        :info,
        "Successfully created calendar event '#{@title}' with ID: #{result.id}"
      )
      
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_calendar_service
    @service = Google::Apis::CalendarV3::CalendarService.new
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
    @service.authorization = authorizer
  end

  def create_event_object
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: Time.zone.name
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: Time.zone.name
      }
    )

    if @attendees.any?
      event.attendees = @attendees.map { |email| { email: email } }
    end

    event
  end
end