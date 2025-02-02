require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows for automated scheduling and reminders based on AI-generated insights or tasks.
#
# It is initialized with a calendar_id, event_details (hash containing :summary, :description, :start_time, :end_time), and optional attendees.
# It returns the ID of the newly created event.
#
# Example usage: When you want to automatically schedule meetings or reminders from AI-generated tasks.

class GoogleCalendarEventCreatorAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Sublayer Google Calendar API Ruby'
  CREDENTIALS_PATH = 'path/to/credentials.json' # Provide the path to your credentials file
  TOKEN_PATH = 'token.yaml'
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  def initialize(calendar_id:, event_details:, attendees: [])
    @calendar_id = calendar_id
    @event_details = event_details
    @attendees = attendees
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def call
    begin
      event = create_event
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def authorize
    client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  def create_event
    Google::Apis::CalendarV3::Event.new(
      summary: @event_details[:summary],
      description: @event_details[:description],
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @event_details[:start_time],
        time_zone: 'UTC'
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @event_details[:end_time],
        time_zone: 'UTC'
      ),
      attendees: @attendees.map { |email| {email: email} }
    )
  end
end
