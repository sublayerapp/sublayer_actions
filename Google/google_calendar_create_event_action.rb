require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows AI agents to schedule meetings or create calendar entries
# with support for title, description, start/end times, attendees, and meeting links.
#
# Requires: google-api-client gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# Required environment variables:
# - GOOGLE_CALENDAR_CREDENTIALS: Path to Google Calendar API credentials JSON file
#
# Example usage: When you want an AI agent to schedule meetings or create calendar
# entries based on analyzed communications or task requirements.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(
    summary:,
    start_time:,
    end_time:,
    description: nil,
    attendees: [],
    create_meet_link: false,
    timezone: 'UTC'
  )
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @create_meet_link = create_meet_link
    @timezone = timezone
    setup_calendar_service
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event('primary', event)
      
      Sublayer.configuration.logger.log(
        :info,
        "Calendar event created successfully: #{result.html_link}"
      )
      
      {
        id: result.id,
        html_link: result.html_link,
        meet_link: result.conference_data&.entry_points&.first&.uri
      }
    rescue Google::Apis::Error => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_calendar_service
    @service = Google::Apis::CalendarV3::CalendarService.new
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
    @service.authorization = authorizer
  end

  def create_event_object
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      start: {
        date_time: format_time(@start_time),
        time_zone: @timezone
      },
      end: {
        date_time: format_time(@end_time),
        time_zone: @timezone
      }
    )

    # Add attendees if specified
    if @attendees.any?
      event.attendees = @attendees.map { |email| { email: email } }
    end

    # Add Google Meet link if requested
    if @create_meet_link
      event.conference_data = Google::Apis::CalendarV3::ConferenceData.new(
        create_request: Google::Apis::CalendarV3::CreateConferenceRequest.new(
          request_id: SecureRandom.uuid,
          conference_solution_key: {
            type: 'hangoutsMeet'
          }
        )
      )
    end

    event
  end

  def format_time(time)
    case time
    when String
      time # Assume it's already in RFC3339 format
    when Time
      time.strftime('%FT%T%:z') # Convert to RFC3339
    else
      raise ArgumentError, 'Time must be a String in RFC3339 format or a Time object'
    end
  end
end