require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action can be used to schedule follow-ups or tasks based on AI analysis or generated content.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details such as summary, location, description, start_time, and end_time.
# It returns the ID of the created event.
#
# Example usage: When you want to automatically schedule a follow-up meeting or task based on AI-generated insights.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(summary:, location: nil, description: nil, start_time:, end_time:, attendees: [])
    @summary = summary
    @location = location
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_APPLICATION_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
  end

  def call
    begin
      event = Google::Apis::CalendarV3::Event.new(
        summary: @summary,
        location: @location,
        description: @description,
        start: { date_time: @start_time.iso8601 },
        end: { date_time: @end_time.iso8601 },
        attendees: @attendees.map { |email| { email: email } }
      )

      result = @service.insert_event('primary', event)
      Sublayer.configuration.logger.log(:info, "Event created: #{result.html_link}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end