require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action allows for scheduling events with details like title, description, start time, end time, and attendees.
#
# Requires: `google-api-client` gem
# $ gem install google-api-client
#
# It is initialized with a calendar_id, event details including title, description,
# start_time, end_time, and attendees.
# It returns the event id to confirm it was created successfully.
#
# Example usage: When you need to schedule a meeting or event programmatically in Google Calendar.

class GoogleCalendarEventSchedulerAction < Sublayer::Actions::Base
  def initialize(calendar_id:, title:, description:, start_time:, end_time:, attendees: [])
    @calendar_id = calendar_id
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees.map { |email| { email: email } }
    @client = Google::Apis::CalendarV3::CalendarService.new
    @client.client_options.application_name = "Sublayer AI"
    @client.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])
  end

  def call
    event = build_event
    result = @client.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Event created successfully: #{result.id}")
    result.id
  rescue Google::Apis::Error => e
    error_message = "Error creating Google Calendar event: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def build_event
    Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @start_time,
        time_zone: 'UTC'
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @end_time,
        time_zone: 'UTC'
      ),
      attendees: @attendees
    )
  end
end
