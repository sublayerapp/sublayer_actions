require 'google/apis/calendar_v3'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows for automated calendar event creation based on AI-generated scheduling data.
#
# Requires: 'google-apis-calendar_v3' gem
# $ gem install google-apis-calendar_v3
# Or add `gem 'google-apis-calendar_v3'` to your Gemfile
#
# It is initialized with event details including title, description, start/end times, and attendees.
# It returns the created event's ID on success.
#
# Example usage: When you want to automatically schedule meetings or create calendar events
# based on AI-processed communications or scheduling suggestions.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [], calendar_id: 'primary')
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @calendar_id = calendar_id
    
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = get_authorization
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Created calendar event '#{@title}' with ID: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def get_authorization
    # Assuming credentials are loaded from a service account or OAuth2
    # You should implement this based on your authentication method
    credentials = Google::Auth::ServiceAccountCredentials.from_env(
      scope: 'https://www.googleapis.com/auth/calendar'
    )
    credentials
  end

  def create_event_object
    Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: Time.zone.name
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: Time.zone.name
      },
      attendees: format_attendees,
      reminders: {
        use_default: true
      }
    )
  end

  def format_attendees
    @attendees.map { |email| { email: email } }
  end
end