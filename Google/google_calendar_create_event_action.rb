require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action enables AI workflows to schedule meetings or reminders based on generated insights or patterns.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add `gem 'google-apis-calendar_v3'` and `gem 'googleauth'` to your Gemfile
#
# It is initialized with event details such as summary, start_time, end_time, and optionally description and attendees.
# It returns the ID of the created event.
#
# Example usage: When you want to automatically schedule a meeting or create a reminder based on AI-generated insights.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(summary:, start_time:, end_time:, description: nil, attendees: [])
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
  end

  def call
    begin
      event = Google::Apis::CalendarV3::Event.new(
        summary: @summary,
        description: @description,
        start: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: @start_time.iso8601,
          time_zone: 'UTC'
        ),
        end: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: @end_time.iso8601,
          time_zone: 'UTC'
        ),
        attendees: @attendees.map { |email| { email: email } }
      )

      result = @service.insert_event('primary', event)
      Sublayer.configuration.logger.log(:info, "Created Google Calendar event: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
