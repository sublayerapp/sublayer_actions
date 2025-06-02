require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action integrates with Google Calendar API to create calendar events with specified details.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, description, start/end times, and optional attendees.
# It returns the ID of the created calendar event.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar events based on
# generated content, analysis, or user interactions.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [], calendar_id: 'primary')
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @calendar_id = calendar_id
    
    initialize_client
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Created Google Calendar event: #{result.id}")
      result.id
    rescue Google::Apis::AuthorizationError => e
      error_message = "Authorization error with Google Calendar API: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::ClientError => e
      error_message = "Client error while creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::ServerError => e
      error_message = "Server error from Google Calendar API: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_client
    @service = Google::Apis::CalendarV3::CalendarService.new
    
    # Authenticate using service account or OAuth2
    if ENV['GOOGLE_CALENDAR_CREDENTIALS_JSON']
      auth = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(ENV['GOOGLE_CALENDAR_CREDENTIALS_JSON']),
        scope: Google::Apis::CalendarV3::AUTH_CALENDAR
      )
    else
      auth = Google::Auth::ServiceAccountCredentials.from_env(
        scope: Google::Apis::CalendarV3::AUTH_CALENDAR
      )
    end

    @service.authorization = auth
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