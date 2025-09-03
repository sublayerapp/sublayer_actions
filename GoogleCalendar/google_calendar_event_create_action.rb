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
# It is initialized with event details including title, start_time, end_time, and optional attendees.
# It returns the ID of the created calendar event.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar events
# based on analyzed content or generated plans.

class GoogleCalendarEventCreateAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [], calendar_id: 'primary')
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @calendar_id = calendar_id
    @service = initialize_calendar_service
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

  def initialize_calendar_service
    service = Google::Apis::CalendarV3::CalendarService.new
    
    # Loads credentials from GOOGLE_APPLICATION_CREDENTIALS environment variable
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      scope: ['https://www.googleapis.com/auth/calendar']
    )
    
    service.authorization = authorizer
    service
  end

  def create_event_object
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: 'UTC'
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: 'UTC'
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