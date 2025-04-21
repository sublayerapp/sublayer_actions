require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows for programmatic creation of calendar events, which is useful
# for AI agents that need to schedule follow-ups or create tasks with deadlines.
#
# Requires:
# - google-api-client gem
# - Setup of Google Calendar API credentials and OAuth2 authentication
# 
# Environment Variables Required:
# - GOOGLE_CALENDAR_CREDENTIALS: Path to service account JSON key file
# - GOOGLE_CALENDAR_ID: ID of the Google Calendar to use (typically email for personal calendars)
#
# Example usage: When an AI agent needs to schedule a follow-up meeting or create
# a task with a specific deadline in a calendar.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(summary:, start_time:, end_time:, description: nil, attendees: [], location: nil)
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @location = location
    @calendar_id = ENV['GOOGLE_CALENDAR_ID']
    setup_client
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Created calendar event: #{result.id}")
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
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
    @service.authorization = authorizer
  end

  def create_event_object
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      location: @location,
      start: {
        date_time: @start_time.iso8601,
        time_zone: Time.zone.name
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: Time.zone.name
      }
    )

    unless @attendees.empty?
      event.attendees = @attendees.map { |email| { email: email } }
    end

    event
  end
end