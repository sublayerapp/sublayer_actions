require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action enables AI agents to schedule meetings or create calendar entries
# based on analyzed content or user interactions.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, description, start_time,
# end_time, and optional attendees.
# It returns the created event's ID to confirm successful creation.
#
# Example usage: When an AI agent needs to schedule a meeting based on
# conversation analysis or task requirements.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, description:, start_time:, end_time:, attendees: [])
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @calendar_id = 'primary'
    
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = authorize
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

  def authorize
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: 'https://www.googleapis.com/auth/calendar'
    )
    authorizer.fetch_access_token!
    authorizer
  end

  def create_event_object
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: 'Etc/UTC'
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: 'Etc/UTC'
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