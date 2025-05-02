require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action enables AI agents to schedule meetings or create calendar events programmatically.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, start/end times, description,
# and optionally attendees and a meeting link.
# It returns the created event object from the Google Calendar API.
#
# Example usage: When an AI agent needs to schedule a meeting based on task analysis
# or create reminders for important deadlines.

class GoogleCalendarEventCreateAction < Sublayer::Actions::Base
  def initialize(
    title:,
    start_time:,
    end_time:,
    description: nil,
    attendees: [],
    meeting_link: nil,
    calendar_id: 'primary'
  )
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @meeting_link = meeting_link
    @calendar_id = calendar_id
    setup_client
  end

  def call
    begin
      create_calendar_event
    rescue Google::Apis::AuthorizationError => e
      error_message = "Authorization error with Google Calendar API: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::ClientError => e
      error_message = "Client error with Google Calendar API: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def setup_client
    @service = Google::Apis::CalendarV3::CalendarService.new
    # Expects GOOGLE_CALENDAR_CREDENTIALS to contain the path to credentials JSON file
    credentials = Google::Auth::ServiceAccountCredentials.from_env(
      'GOOGLE_CALENDAR_CREDENTIALS'
    )
    credentials.scope = Google::Apis::CalendarV3::AUTH_CALENDAR
    @service.authorization = credentials
  end

  def create_calendar_event
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
      },
      attendees: @attendees.map { |email| { email: email } },
      conference_data: conference_data
    )

    result = @service.insert_event(
      @calendar_id,
      event,
      conference_data_version: @meeting_link ? 1 : 0
    )

    Sublayer.configuration.logger.log(
      :info,
      "Calendar event created successfully: #{result.html_link}"
    )

    result
  end

  def conference_data
    return nil unless @meeting_link

    {
      create_request: {
        request_id: SecureRandom.uuid,
        conference_solution_key: {
          type: 'hangoutsMeet'
        }
      }
    }
  end
end
