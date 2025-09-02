require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating a new event in Google Calendar.
# This action is useful for scheduling automations and reminders based on AI predictions or user inputs.
#
# It is initialized with necessary event details such as title, start_time, end_time, and optionally description, location, attendees, etc..
# It returns the ID of the created event.
#
# Example usage: Automating event creation in Google Calendar for team meetings, reminders, or scheduling tasks.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, title:, start_time:, end_time:, description: nil, location: nil, attendees: [], **kwargs)
    super(**kwargs)
    @calendar_id = calendar_id
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @location = location
    @attendees = attendees
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = 'Sublayer'
    @service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/calendar'])
  end

  def call
    begin
      event = create_event
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: [32m#{event.id}")
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
      location: @location,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time.iso8601),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time.iso8601),
      attendees: @attendees.map { |email| { email: email } }
    )

    @service.insert_event(@calendar_id, event)
  end
end
