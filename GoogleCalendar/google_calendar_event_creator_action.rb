require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Description: Sublayer::Action responsible for creating an event in a specified Google Calendar.
# This action allows for integration with Google Calendar to schedule events with title, description, start and end times, and participants.
#
# Example usage: When you have generated an event from an LLM and want to add it to a Google Calendar for organizational purposes.

class GoogleCalendarEventCreatorAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Sublayer Google Calendar Event Creator'.freeze
  CREDENTIALS_PATH = 'credentials.json'.freeze
  TOKEN_PATH = 'token.yaml'.freeze
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  def initialize(calendar_id:, title:, description:, start_time:, end_time:, attendees: [], **kwargs)
    super(**kwargs)
    @calendar_id = calendar_id
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @start_time.iso8601
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @end_time.iso8601
      ),
      attendees: @attendees.map { |email| { 'email' => email } }
    )

    begin
      @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar.")
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: \\#{e.message}"
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
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end
end
