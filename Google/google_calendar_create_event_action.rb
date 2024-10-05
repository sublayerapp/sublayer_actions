require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action is useful for AI agents to schedule tasks, set reminders, or manage appointments
# based on generated data or user interactions.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details and returns the created event's ID.
#
# Example usage: When an AI agent needs to schedule a task or appointment in Google Calendar.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(summary:, start_time:, end_time:, description: nil, location: nil, attendees: nil, calendar_id: 'primary')
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @location = location
    @attendees = attendees
    @calendar_id = calendar_id
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      location: @location,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: 'UTC',
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: 'UTC',
      },
      attendees: @attendees&.map { |email| { email: email } }
    )

    begin
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created: #{result.html_link}")
      result.id
    rescue Google::Apis::Error => e
      Sublayer.configuration.logger.log(:error, "Error creating Google Calendar event: #{e.message}")
      raise e
    end
  end
end
