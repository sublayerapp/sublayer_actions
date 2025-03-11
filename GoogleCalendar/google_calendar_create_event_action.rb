require 'googleauth'
require 'google/apis/calendar_v3'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action integrates with Google Calendar using the Google API Client,
# allowing automated scheduling of events based on AI-generated insights or analyses.
#
# Requires: 'google-api-client' gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# It is initialized with a calendar_id, summary, start_time, end_time, and optionally description and attendees.
# It returns the ID of the created Google Calendar event.
#
# Example usage: When you want to schedule events in Google Calendar based on AI-generated schedules or team requirements.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, summary:, start_time:, end_time:, description: '', attendees: [])
    @calendar_id = calendar_id
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time),
      attendees: @attendees.map { |email| { email: email } }
    )

    begin
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
