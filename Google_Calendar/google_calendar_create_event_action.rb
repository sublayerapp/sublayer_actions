require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

# Description: Sublayer::Action for scheduling events on Google Calendar.
# It takes parameters like event summary, description, start and end times, and attendee emails.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  SCOPES = ['https://www.googleapis.com/auth/calendar']
  TOKEN_PATH = 'token.yaml'

  def initialize(summary:, description:, start_time:, end_time:, attendee_emails: [], calendar_id: 'primary')
    @summary = summary
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendee_emails = attendee_emails
    @calendar_id = calendar_id
    @service = initialize_calendar_service
  end

  def call
    begin
      event = create_event
      Sublayer.configuration.logger.log(:info, "Google Calendar event created successfully: #{event.id}")
      event.id
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error creating Google Calendar event: #{e.message}")
      raise e
    end
  end

  private

  def initialize_calendar_service
    service = Google::Apis::CalendarV3::CalendarService.new
    service.client_options.application_name = 'Sublayer Google Calendar Action'
    service.authorization = authorize
    service
  end

  def authorize
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_APPLICATION_CREDENTIALS']),
      scope: SCOPES
    )
  end


  def create_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      start: {
        date_time: @start_time.to_datetime.rfc3339
      },
      end: {
        date_time: @end_time.to_datetime.rfc3339
      },
      attendees: @attendee_emails.map { |email| { email: email } }
    )

    @service.insert_event(@calendar_id, event)
  end
end