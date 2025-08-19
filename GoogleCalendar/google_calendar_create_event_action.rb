require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows for easy integration with Google Calendar for scheduling meetings
# or creating reminders based on AI-generated content.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, description, start_time, end_time,
# and optional attendees list.
# It returns the ID of the created calendar event.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar
# events based on analyzed content or automated workflows.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, description:, start_time:, end_time:, attendees: [], time_zone: 'UTC')
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @time_zone = time_zone
    @calendar_id = 'primary' # Using primary calendar by default
    
    setup_client
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Calendar event created successfully with ID: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_client
    @service = Google::Apis::CalendarV3::CalendarService.new
    
    # Expects GOOGLE_CALENDAR_CREDENTIALS to contain the path to service account JSON
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
    
    @service.authorization = authorizer
  rescue StandardError => e
    error_message = "Error setting up Google Calendar client: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
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