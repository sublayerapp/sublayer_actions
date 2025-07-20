require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for scheduling events on Google Calendar.
# This action integrates with Google Calendar API and can be used to schedule meetings
# based on outcomes from AI processes, enhancing productivity workflows.
#
# Example usage: Automatically add AI-suggested meetings to your calendar.

class GoogleCalendarEventSchedulerAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, attendees: [], description: '')
    @title = title
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @description = description
    @calendar_service = setup_calendar_service
  end

  def call
    begin
      event = create_event
      result = @calendar_service.insert_event('primary', event)
      Sublayer.configuration.logger.log(:info, "Event created successfully: \\#{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Failed to create Google Calendar event: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error when creating event: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def setup_calendar_service
    scopes = ['https://www.googleapis.com/auth/calendar']
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(ENV['GOOGLE_SERVICE_ACCOUNT_JSON']),
      scope: scopes
    )
    authorizer.fetch_access_token!

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = authorizer
    service
  end

  def create_event
    Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @start_time,
        time_zone: 'UTC'
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @end_time,
        time_zone: 'UTC'
      ),
      attendees: @attendees.map { |email| { email: email } }
    )
  end
end