require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows for programmatic creation of calendar events with specified details
# including title, description, timing, and attendees.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# The action requires Google Calendar API credentials in the GOOGLE_CALENDAR_CREDENTIALS env variable
# and uses application default credentials for authentication.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar events
# based on conversation analysis or task planning.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [], time_zone: 'UTC')
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @time_zone = time_zone
    
    setup_calendar_service
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event('primary', event)
      
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
    @service.authorization = Google::Auth::DefaultCredentials.make_creds(
      json_key_io: StringIO.new(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
  end

  def create_event_object
    Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @start_time.iso8601,
        time_zone: @time_zone
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @end_time.iso8601,
        time_zone: @time_zone
      ),
      attendees: @attendees.map { |email| { email: email } }
    )
  end
end