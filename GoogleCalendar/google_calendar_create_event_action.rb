require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows for programmatic creation of calendar events, which is useful
# for AI agents that need to schedule meetings or events based on analysis or generated content.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, start_time, end_time, and optional
# parameters like description, attendees, and location.
# It returns the ID of the created calendar event.
#
# Example usage: When you want an AI agent to automatically schedule meetings or create
# calendar events based on task analysis or conversation context.

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
    @service.authorization = Google::Auth::ServiceAccountCredentials.from_env(
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
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def build_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      start: {
        date_time: @start_time.iso8601,
        time_zone: Time.zone.name
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: Time.zone.name
      }
    )

    event.description = @description if @description
    event.location = @location if @location
    
    if @attendees.any?
      event.attendees = @attendees.map do |email|
        Google::Apis::CalendarV3::EventAttendee.new(email: email)
      end
    end

    event
  end
end