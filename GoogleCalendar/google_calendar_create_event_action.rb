require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# It is initialized with event details like title, date, and attendees, 
# and it creates an event in the specified Google Calendar.
#
# Example usage: When you want to schedule a meeting or event based on AI recommendations
# or user input, this action can be used to add it to a Google Calendar.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_title:, start_time:, end_time:, attendees: [])
    @calendar_id = calendar_id
    @event_title = event_title
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = 'SublayerApp'
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])
  end

  def call
    begin
      event = create_event
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{result.id}")
      result
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_event
    Google::Apis::CalendarV3::Event.new(
      summary: @event_title,
      start: {
        date_time: @start_time,
        time_zone: 'UTC'
      },
      end: {
        date_time: @end_time,
        time_zone: 'UTC'
      },
      attendees: @attendees.map { |email| { email: email } }
    )
  end
end
