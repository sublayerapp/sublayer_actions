require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows for programmatic creation of calendar events, which is useful
# for AI agents that need to schedule meetings or reminders based on context.
#
# Requires: google-api-client gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# It is initialized with event details including title, start_time, end_time,
# and optional parameters like description, attendees, and location.
# It returns the ID of the created calendar event.
#
# Example usage: When an AI agent needs to schedule a follow-up meeting
# or create a reminder based on conversation context or task analysis.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [], location: nil, calendar_id: 'primary')
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @location = location
    @calendar_id = calendar_id
    
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: 'https://www.googleapis.com/auth/calendar'
    )
  end

  def call
    begin
      event = build_event
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Successfully created calendar event: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def build_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      start: {
        date_time: @start_time.iso8601,
        time_zone: 'UTC'
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: 'UTC'
      }
    )

    event.description = @description if @description
    event.location = @location if @location
    
    if @attendees.any?
      event.attendees = @attendees.map { |email| { email: email } }
    end

    event
  end
end
