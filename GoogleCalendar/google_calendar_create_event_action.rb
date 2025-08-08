require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in a specified Google Calendar.
# This action facilitates automated scheduling by integrating with the Google Calendar API.
#
# It is initialized with calendar_id, event_summary, event_start_time, and event_end_time, 
# along with optional description and attendees.
# It returns the ID of the created Google Calendar event.
#
# Example usage: When you need to automatically schedule meetings or events based on AI-generated insights.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_summary:, event_start_time:, event_end_time:, description: nil, attendees: [])
    @calendar_id = calendar_id
    @event_summary = event_summary
    @event_start_time = event_start_time
    @event_end_time = event_end_time
    @description = description
    @attendees = attendees.map { |email| { email: email } }
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])
  end

  def call
    begin
      event = Google::Apis::CalendarV3::Event.new(
        summary: @event_summary,
        start: { date_time: @event_start_time.to_datetime.rfc3339 },
        end: { date_time: @event_end_time.to_datetime.rfc3339 },
        description: @description,
        attendees: @attendees
      )

      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
