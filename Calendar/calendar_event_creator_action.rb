require 'google/apis/calendar_v3'
require 'googleauth'
require 'date'

# Description: Sublayer::Action responsible for creating events in a user's Google Calendar.
# This action allows for easy scheduling of tasks or deliverables, helping manage schedules and deadlines effectively.
#
# It is initialized with a calendar_id, event_title, start_time, end_time, and optionally, description and attendees.
# It returns the ID of the created calendar event.
#
# Example usage: When you want to automatically schedule a task or deliverable as a calendar event.

class CalendarEventCreatorAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_title:, start_time:, end_time:, description: nil, attendees: [])
    @calendar_id = calendar_id
    @event_title = event_title
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
      Sublayer.configuration.logger.log(:info, "Event created successfully: #{result.id}")
      result.id
    rescue Google::Apis::ClientError => e
      error_message = "Client error during event creation: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def create_event
    Google::Apis::CalendarV3::Event.new(
      summary: @event_title,
      description: @description,
      start: {
        date_time: @start_time.to_datetime.rfc3339
      },
      end: {
        date_time: @end_time.to_datetime.rfc3339
      },
      attendees: @attendees.map { |email| { email: email } }
    )
  end
end