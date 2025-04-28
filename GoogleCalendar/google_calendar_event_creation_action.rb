require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action for creating an event in Google Calendar.
# This action allows integrating Google Calendar event creation into Sublayer workflows for automating scheduling tasks.
#
# Example usage: When you need to schedule a meeting or set a reminder as part of an AI-driven workflow.

class GoogleCalendarEventCreationAction < Sublayer::Actions::Base
  def initialize(calendar_id:, summary:, start_time:, end_time:, description: nil, attendees: [], **kwargs)
    super(**kwargs)
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
    begin
      event = create_event
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{result.id}")
      result
    rescue Google::Apis::Error => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_event
    Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time),
      attendees: @attendees.map { |email| { email: email } }
    )
  end
end