require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows AI agents to programmatically schedule meetings or create calendar events.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, description, start_time, end_time,
# and optional attendees list. Returns the created event's ID.
#
# Authentication requires a Google Cloud project and OAuth2 credentials:
# 1. Set up a Google Cloud project and enable the Calendar API
# 2. Create OAuth 2.0 credentials and download the client configuration
# 3. Set GOOGLE_CALENDAR_CREDENTIALS env var to the path of your credentials file
#
# Example usage: When an AI agent needs to schedule a meeting based on a conversation
# or create a reminder for a future task.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, description:, start_time:, end_time:, attendees: [], time_zone: 'UTC')
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @time_zone = time_zone
    setup_client
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event('primary', event)
      
      Sublayer.configuration.logger.log(:info, "Successfully created calendar event: #{result.id}")
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
    
    # Load credentials from the specified file
    credentials_path = ENV['GOOGLE_CALENDAR_CREDENTIALS']
    if !credentials_path || !File.exist?(credentials_path)
      raise StandardError, 'Google Calendar credentials file not found'
    end

    credentials = Google::Auth::DefaultCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )

    @service.authorization = credentials
  end

  def create_event_object
    Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: @time_zone
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: @time_zone
      },
      attendees: @attendees.map { |email| { email: email } },
      reminders: {
        use_default: true
      }
    )
  end
end