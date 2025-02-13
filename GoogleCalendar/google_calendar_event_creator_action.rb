require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating a new event in Google Calendar.
# This action allows integration with Google Calendar, enabling the automation of event creation based on AI-driven insights or processes.
#
# Requires: 'google-api-client' gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# It is initialized with a calendar_id, summary, start_time, end_time, and optional description and location.
# It returns the event ID of the newly created event.
#
# Example usage: When you want to automatically schedule meetings or reminders in Google Calendar as part of an AI workflow.

class GoogleCalendarEventCreatorAction < Sublayer::Actions::Base
  def initialize(calendar_id:, summary:, start_time:, end_time:, description: nil, location: nil)
    @calendar_id = calendar_id
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @location = location
    @client = Google::Apis::CalendarV3::CalendarService.new
    @client.client_options.application_name = 'Sublayer Google Calendar Integration'
    @client.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      location: @location,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time.iso8601),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time.iso8601)
    )
    created_event = @client.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Google Calendar event created successfully: \\#{created_event.id}")
    created_event.id
  rescue Google::Apis::Error => e
    error_message = "Error creating Google Calendar event: \\#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end
