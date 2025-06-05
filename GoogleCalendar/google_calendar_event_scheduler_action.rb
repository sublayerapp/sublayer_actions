require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

# Description: Sublayer::Action responsible for scheduling an event in a user's Google Calendar.
# This action is suitable for managing deadlines or reminders based on AI-generated outputs.
#
# It is initialized with a calendar_id, event_details (including summary, start_time, end_time, and optional description, location),
# and returns the event ID upon successful creation.
#
# Example usage: When you want to create a deadline or reminder in a user's Google Calendar based on AI outputs.

class GoogleCalendarEventSchedulerAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Sublayer Google Calendar Integration'.freeze
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  def initialize(calendar_id:, event_details:, credentials_path: 'token.yaml', client_secrets_path: 'client_secret.json')
    @calendar_id = calendar_id
    @event_details = event_details
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize(credentials_path, client_secrets_path)
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @event_details[:summary],
      location: @event_details[:location],
      description: @event_details[:description],
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @event_details[:start_time]),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @event_details[:end_time])
    )
    result = @service.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{result.id}")
    result.id
  rescue Google::Apis::Error => e
    error_message = "Error creating event in Google Calendar: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def authorize(credentials_path, client_secrets_path)
    client_id = Google::Auth::ClientId.from_file(client_secrets_path)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: credentials_path)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the resulting code after authorization: \n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end
end
