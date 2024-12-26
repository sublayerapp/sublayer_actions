require 'google/apis/calendar_v3'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows integration with Google Calendar, enabling automated event scheduling.
#
# It is initialized with event details like title, description, date, time, and attendees.
# It returns the event ID.
#
# Example usage: Scheduling meetings based on AI-generated summaries or code analysis results.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, description:, start_time:, end_time:, attendees: [], calendar_id: 'primary')
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @calendar_id = calendar_id

    @client = Google::Apis::CalendarV3::CalendarService.new
    @client.client_options.application_name = 'Sublayer Actions'
    @client.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/calendar'])
  end

  def call
    begin
      event = Google::Apis::CalendarV3::Event.new(
        summary: @title,
        description: @description,
        start: {
          date_time: @start_time.to_datetime.rfc3339
        },
        end: {
          date_time: @end_time.to_datetime.rfc3339
        },
        attendees: @attendees.map { |email| { email: email } }
      )

      created_event = @client.insert_event(@calendar_id, event)

      Sublayer.configuration.logger.log(:info, "Google Calendar event created successfully: #{created_event.id}")

      created_event.id
    rescue StandardError => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end