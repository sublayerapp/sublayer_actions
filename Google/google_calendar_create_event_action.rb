require 'google/apis/calendar_v3'
require 'google/api_client/client_secrets'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action integrates with Google Calendar API to create calendar events with specified details.
#
# Requires: 'google-api-client' gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# Required environment variables:
# - GOOGLE_CALENDAR_CREDENTIALS: Path to Google Calendar API credentials JSON file
#
# It is initialized with event title, start_time, end_time, and optional description and attendees.
# It returns the created event's ID on success.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar events
# based on analyzed data or generated content.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [])
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @service = initialize_service
  end

  def call
    begin
      event = create_event
      Sublayer.configuration.logger.log(:info, "Created Google Calendar event: #{event.id}")
      event.id
    rescue Google::Apis::ClientError => e
      error_message = "Client error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::ServerError => e
      error_message = "Server error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def initialize_service
    service = Google::Apis::CalendarV3::CalendarService.new
    credentials = Google::APIClient::ClientSecrets.load(ENV['GOOGLE_CALENDAR_CREDENTIALS'])
    
    service.authorization = credentials.to_authorization
    service.authorization.refresh!
    service
  end

  def create_event
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
      },
      attendees: @attendees.map { |email| { email: email } }
    )

    @service.insert_event('primary', event)
  end
end