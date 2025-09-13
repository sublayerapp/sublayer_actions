require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating a new event in Google Calendar.
# This action integrates scheduling capabilities into Sublayer workflows, enabling AI-driven processes to automatically schedule events.
#
# It is initialized with calendar_id, event_title, start_time, end_time, and optionally description and location.
# It returns the ID of the newly created event.
#
# Example usage: When you want to schedule a meeting or reminder based on AI-generated insights or decisions in a Sublayer workflow.

class GoogleCalendarEventCreationAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_title:, start_time:, end_time:, description: nil, location: nil)
    @calendar_id = calendar_id
    @event_title = event_title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @location = location
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/calendar'])
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @event_title,
      location: @location,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time)
    )

    begin
      created_event = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Google Calendar event created successfully: #{created_event.id}")
      created_event.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
