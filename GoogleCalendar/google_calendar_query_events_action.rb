require 'google/apis/calendar_v3'
require 'date'

# Description: Queries a Google Calendar for events within a given time range.
# Useful for integrating AI scheduling and planning into workflows.

class GoogleCalendarQueryEventsAction < Sublayer::Actions::Base
  def initialize(calendar_id:, start_time:, end_time:)
    @calendar_id = calendar_id
    @start_time = start_time
    @end_time = end_time
    @client = Google::Apis::CalendarV3::CalendarService.new
    @client.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/calendar.readonly'])
  end

  def call
    begin
      events = @client.list_events(
        @calendar_id,
        time_min: @start_time.iso8601,
        time_max: @end_time.iso8601,
        single_events: true,
        order_by: 'startTime'
      )
      Sublayer.configuration.logger.log(:info, "Successfully retrieved events from Google Calendar #{@calendar_id}")

      events.items
    rescue Google::Apis::ClientError => e
      error_message = "Error querying Google Calendar: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end