require 'googleauth'
require 'google/apis/calendar_v3'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action allows integration with Google Calendar to automate scheduling tasks.
#
# It is initialized with a calendar_id, title, start_time, end_time, and attendees.
# It returns the ID of the created event.
#
# Example usage: Create a meeting invite based on LLM's evaluation of availability and priorities.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, title:, start_time:, end_time:, attendees: [], **kwargs)
    super(**kwargs)
    @calendar_id = calendar_id
    @title = title
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])  
  end

  def call
    begin
      event = create_event
      Sublayer.configuration.logger.log(:info, "Google Calendar event created successfully: #{event.id}")
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
      summary: @title,
      start: {
        date_time: @start_time
      },
      end: {
        date_time: @end_time
      },
      attendees: @attendees.map { |email| { email: email } }
    )
    @service.insert_event(@calendar_id, event)
  end
end