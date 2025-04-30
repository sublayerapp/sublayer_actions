require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating and managing Google Calendar events based on actions or deadlines specified in an integrated task management system.
#
# It is initialized with event details such as summary, location, 
# description, start_time, and end_time.
# It returns the event ID of the created or managed Google Calendar event.
#
# Example usage: When you want to create or update a Google Calendar event based on task deadlines.

class GoogleCalendarEventCreatorAction < Sublayer::Actions::Base
  def initialize(summary:, location: nil, description: nil, start_time:, end_time:, calendar_id: 'primary')
    @summary = summary
    @location = location
    @description = description
    @start_time = start_time
    @end_time = end_time
    @calendar_id = calendar_id
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = 'Sublayer'
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])
  end

  def call
    begin
      event = create_event
      created_event = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Google Calendar event created successfully: #{created_event.id}")
      created_event.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_event
    Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      location: @location,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @start_time.to_datetime.rfc3339
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @end_time.to_datetime.rfc3339
      )
    )
  end
end