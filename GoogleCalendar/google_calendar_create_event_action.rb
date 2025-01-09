require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating a new event in Google Calendar.
# This action allows integration with Google Calendar to automate event creation.
# It is initialized with event details such as title, start time, end time, and attendees.
# It returns the ID of the created event as confirmation.
#
# Example usage: Automating meeting scheduling by creating events in Google Calendar based on AI outputs.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, title:, start_time:, end_time:, attendees: [])
    @calendar_id = calendar_id
    @title = title
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @service = Google::Apis::CalendarV3::CalendarService.new
    authorize
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time),
      attendees: @attendees.map { |email| { email: email } }
    )
    result = @service.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Successfully created Google Calendar event with ID: #{result.id}")
    result.id
  rescue Google::Apis::ClientError => e
    error_message = "Error creating Google Calendar event: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def authorize
    @service.client_options.application_name = 'Sublayer'
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
    @service.authorization.fetch_access_token!
  rescue StandardError => e
    error_message = "Authorization failed: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end