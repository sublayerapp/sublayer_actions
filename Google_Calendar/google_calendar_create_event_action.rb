require 'google/apis/calendar_v3'

# Description: Sublayer::Action for creating events on a Google Calendar.
# Takes event details like summary, description, start/end times, and timezone as input.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, summary:, description: nil, start_time:, end_time:, timezone: 'America/Los_Angeles')
    @calendar_id = calendar_id
    @summary = summary
    @description = description
    @start_time = start_time
    @end_time = end_time
    @timezone = timezone

    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/calendar'])
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error initializing Google Calendar service: #{e.message}")
    raise e
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: @timezone
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: @timezone
      }
    )

    begin
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully: #{result.id}")
      result.id # Return the event ID for reference
    rescue Google::Apis::ClientError => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end