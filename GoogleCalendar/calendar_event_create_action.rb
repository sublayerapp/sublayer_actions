require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action allows for integration with Google Calendar to schedule events like reminders, meetings, 
# or tasks based on AI-driven insights.
#
# Requires: 'google-api-client' gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# It is initialized with a calendar_id, event_description, event_date, and event_time. 
# It returns the event_id on successful creation.
#
# Example usage: When you want to schedule an event in Google Calendar based on AI-generated insights.

class CalendarEventCreateAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Sublayer Calendar Integration'.freeze
  TOKEN_PATH = 'token.yaml'.freeze
  CREDENTIALS_PATH = 'credentials.json'.freeze
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  def initialize(calendar_id:, event_description:, event_date:, event_time:)
    @calendar_id = calendar_id
    @event_description = event_description
    @event_date = event_date
    @event_time = event_time
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def call
    event = create_event
    result = @service.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: \\#{result.id}")
    result.id
  rescue Google::Apis::Error => e
    error_message = "Error creating Google Calendar event: \\#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
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
      puts "Open the following URL in the browser and enter the resulting code after authorization:\n\\#{url}"
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  def create_event
    Google::Apis::CalendarV3::Event.new(
      summary: @event_description,
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: DateTime.parse("\\#{@event_date} \\#{@event_time}"),
        time_zone: 'UTC'
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: (DateTime.parse("\\#{@event_date} \\#{@event_time}") + (1.0/24)),
        time_zone: 'UTC'
      )
    )
  end
end
