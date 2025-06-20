require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action is intended to automate the process of scheduling meetings and events.
#
# It is initialized with parameters like start_time, end_time, attendees, summary, and description.
# It returns the ID of the created event to confirm it was created successfully.
#
# Example usage: When you want to schedule meetings automatically based on output from an AI process.

class GoogleCalendarEventCreateAction < Sublayer::Actions::Base
  def initialize(calendar_id:, start_time:, end_time:, summary:, description: '', attendees: [])
    @calendar_id = calendar_id
    @start_time = start_time
    @end_time = end_time
    @summary = summary
    @description = description
    @attendees = attendees.map { |email| { email: email } }
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/calendar'])
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time),
      attendees: @attendees
    )

    begin
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{result.id}")
      result.id
    rescue Google::Apis::RequestError => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
