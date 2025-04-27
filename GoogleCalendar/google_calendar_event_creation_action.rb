# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows integration with Google Calendar to automate event creation based on AI-generated schedules or prompts.
#
# It is initialized with event details such as summary, start time, end time, and optionally location and description.
# It returns the ID of the created Google Calendar event to confirm successful creation.
#
# Example usage: When you want to automatically schedule meetings, reminders, or events using AI-generated outputs.

require 'google/apis/calendar_v3'
require 'googleauth'

class GoogleCalendarEventCreationAction < Sublayer::Actions::Base
  def initialize(summary:, start_time:, end_time:, location: nil, description: nil, calendar_id: 'primary', **kwargs)
    super(**kwargs)
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @location = location
    @description = description
    @calendar_id = calendar_id
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = authorize
  end

  def call
    event = create_event
    result = @service.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Calendar event created successfully: \\#{result.id}")
    result.id
  rescue Google::Apis::ClientError => e
    error_message = "Error creating Google Calendar event: \\#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def create_event
    Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      location: @location,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time, time_zone: 'UTC'),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time, time_zone: 'UTC')
    )
  end

  def authorize
    # Load the credentials from a service account file or use environment variables
    # Ensure the Calendar API is enabled in GCP and appropriate access is provided.
    scopes = ['https://www.googleapis.com/auth/calendar']
    Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']), scope: scopes)
  end
end
