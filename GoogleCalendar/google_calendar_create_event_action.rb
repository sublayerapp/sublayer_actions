require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action integrates with the Google Calendar API to create calendar events
# with specified details such as title, description, timing, and attendees.
#
# Requires: 'google-api-client' and 'googleauth' gems
# $ gem install google-api-client googleauth
# Or add to your Gemfile:
# gem 'google-api-client'
# gem 'googleauth'
#
# Authentication:
# Requires a Google Cloud service account credentials JSON file path in
# GOOGLE_CALENDAR_CREDENTIALS environment variable
#
# Example usage: When you want to schedule follow-up meetings or create calendar
# events based on AI-generated content or automated processes.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [], calendar_id: 'primary')
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @calendar_id = calendar_id
    setup_calendar_service
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Calendar event created successfully: #{result.html_link}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_calendar_service
    @service = Google::Apis::CalendarV3::CalendarService.new
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
    @service.authorization = credentials
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

    unless @attendees.empty?
      event.attendees = @attendees.map { |email| { email: email } }
    end

    event
  end
end