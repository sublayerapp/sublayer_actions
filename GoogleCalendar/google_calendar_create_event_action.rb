require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# It integrates with Google Calendar using the Google Calendar API.
#
# It is initialized with a calendar_id, summary, start_time, end_time, and optional description.
# It returns the ID of the created event.
#
# Example usage: When you want to schedule an AI-generated reminder or task into your Google Calendar.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, summary:, start_time:, end_time:, description: nil)
    @calendar_id = calendar_id
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])  
  end

  def call
    begin
      event = create_event
      Sublayer.configuration.logger.log(:info, "Google Calendar event created successfully with ID: #{event.id}")
      event.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time)
    )

    @service.insert_event(@calendar_id, event)
  end
end
