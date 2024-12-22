require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action simplifies the process of integrating with Google Calendar to add events
# by specifying event details such as date, time, name, and description.
#
# Example usage: Automating the scheduling of meetings or reminders in Google Calendar
# based on AI-driven processes or external inputs.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(summary:, start_time:, end_time:, description:, **kwargs)
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @service = initialize_google_calendar_service(**kwargs)
  end

  def call
    event = create_event
    insert_event(event)
  end

  private

  def initialize_google_calendar_service(credentials_path: ENV['GOOGLE_CREDENTIALS_PATH'])
    Google::Apis::CalendarV3::CalendarService.new.tap do |service|
      service.client_options.application_name = 'Sublayer'
      service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(credentials_path),
        scope: Google::Apis::CalendarV3::AUTH_CALENDAR
      )
    end
  end

  def create_event
    Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @start_time,
        time_zone: 'UTC'
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @end_time,
        time_zone: 'UTC'
      )
    )
  end

  def insert_event(event)
    begin
      result = @service.insert_event('primary', event)
      Sublayer.configuration.logger.log(:info, "Google Calendar event created successfully: #{result.id}")
      result
    rescue Google::Apis::ClientError => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end