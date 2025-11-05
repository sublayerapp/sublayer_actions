require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
CREDENTIALS_PATH = 'token.yaml'.freeze

# Description: Sublayer::Action responsible for creating an event in a specified Google Calendar.
# It is initialized with a calendar_id, start_time, end_time, summary, and description.
# It returns the event id to verify the event was created.
#
# Example usage: When you have generated a list of tasks from an LLM and want to add them to
# a Google Calendar for a human or an AI agent to work on

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, start_time:, end_time:, summary:, description: nil)
    @calendar_id = calendar_id
    @start_time = start_time
    @end_time = end_time
    @summary = summary
    @description = description
    @client = Google::Apis::CalendarV3::CalendarService.new
    @client.authorization = authorize
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time.to_datetime.rfc3339),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time.to_datetime.rfc3339)
    )

    begin
      result = @client.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully: #{result.id}")
      result.id
    rescue Google::Apis::ServerError => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::ClientError => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user will be prompted to visit the URL in a browser and grant
  # authorization. The credential will be saved to CREDENTIALS_PATH for
  # later use.
  def authorize
    client_id = Google::Auth::ClientId.from_file('credentials.json')
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, Google::Apis::CalendarV3::AUTH_CALENDAR, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts 'Open the following URL in the browser and enter the ' \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id,
        code: code,
        base_url: OOB_URI
      )
    end
    credentials
  end
end