require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action enables AI workflows to programmatically schedule meetings and create
# calendar events through the Google Calendar API.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, start_time, end_time,
# and optional parameters like description, location, and attendees.
# It returns the ID of the created calendar event.
#
# Example usage: When you want an AI agent to schedule meetings or create reminders
# based on analyzed content or generated plans.

class CalendarEventCreateAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, location: nil, attendees: [], calendar_id: 'primary')
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @location = location
    @attendees = attendees
    @calendar_id = calendar_id
    
    initialize_calendar_service
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

  def initialize_calendar_service
    @service = Google::Apis::CalendarV3::CalendarService.new
    
    # Authenticate using service account if credentials path is provided
    if ENV['GOOGLE_CALENDAR_CREDENTIALS_PATH']
      @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS_PATH']),
        scope: Google::Apis::CalendarV3::AUTH_CALENDAR
      )
    else
      # Fall back to application default credentials
      @service.authorization = Google::Auth.get_application_default(Google::Apis::CalendarV3::AUTH_CALENDAR)
    end
  end

  def create_event_object
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      location: @location,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: ENV['CALENDAR_TIMEZONE'] || 'UTC'
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: ENV['CALENDAR_TIMEZONE'] || 'UTC'
      }
    )

    # Add attendees if provided
    unless @attendees.empty?
      event.attendees = @attendees.map { |email| { email: email } }
    end

    event
  end
end