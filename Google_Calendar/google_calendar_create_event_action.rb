# Description: Sublayer::Action responsible for creating a new Google Calendar event.
# It takes event details like title, description, start/end times, and attendee emails as input.
# Returns event ID.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, description:, start_time:, end_time:, attendees: [], calendar_id: 'primary')
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @calendar_id = calendar_id

    @client = Google::Apis::CalendarV3::CalendarService.new
    @client.client_options.application_name = 'Sublayer'
    @client.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/calendar'])
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time.to_datetime.rfc3339),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time.to_datetime.rfc3339),
      attendees: @attendees.map { |email| Google::Apis::CalendarV3::EventAttendee.new(email: email) }
    )

    begin
      result = @client.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Google Calendar event created successfully: #{result.id}")
      result.id
    rescue Google::Apis::ClientError => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end