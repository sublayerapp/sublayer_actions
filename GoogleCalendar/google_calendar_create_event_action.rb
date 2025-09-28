require 'google/apis/calendar_v3'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action integrates with Google Calendar API to create calendar events with specified details.
#
# Requires: 'google-apis-calendar_v3' gem
# $ gem install google-apis-calendar_v3
# Or add `gem 'google-apis-calendar_v3'` to your Gemfile
#
# It is initialized with event details including title, description, start/end times, and optional attendees.
# It returns the created event's ID on success.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar events
# based on analyzed content, patterns, or automated workflows.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [], calendar_id: 'primary')
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @calendar_id = calendar_id
    @service = initialize_service
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Created calendar event: #{result.id}")
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

  def initialize_service
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = load_credentials
    service
  end

  def load_credentials
    # Assumes credentials are loaded via environment variables or a service account
    # Modify this method based on your authentication setup
    if ENV['GOOGLE_APPLICATION_CREDENTIALS']
      Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(ENV['GOOGLE_APPLICATION_CREDENTIALS']),
        scope: Google::Apis::CalendarV3::AUTH_CALENDAR
      )
    else
      raise StandardError, 'Google Calendar credentials not found'
    end
  end

  def create_event_object
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: Time.zone&.name || 'UTC'
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: Time.zone&.name || 'UTC'
      }
    )

    # Add attendees if specified
    unless @attendees.empty?
      event.attendees = @attendees.map { |email| { email: email } }
    end

    event
  end
end