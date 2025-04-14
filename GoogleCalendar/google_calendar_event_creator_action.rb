require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Description: Sublayer::Action responsible for creating a calendar event in Google Calendar.
# Useful for scheduling or automating event planning processes using AI-generated insights.
#
# Requires: 'google-api-client' gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile and run bundle install.
#
# It is initialized with calendar_id, title, description, start_time, and end_time.
# It returns the ID of the created event for verification.
#
# Example usage: When you have a scheduled task or reminder to add to a Google Calendar based on LLM output.

class GoogleCalendarEventCreatorAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Sublayer Google Calendar Event Creator'
  CLIENT_SECRETS_PATH = 'path/to/client_secret.json'
  CREDENTIALS_PATH = File.join(Dir.home, '.credentials', "calendar-ruby-quickstart.yaml")
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR_EVENTS

  def initialize(calendar_id:, title:, description:, start_time:, end_time:, location: nil)
    @calendar_id = calendar_id
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @location = location
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      location: @location,
      description: @description,
      start: {
        date_time: @start_time.to_datetime.rfc3339,
        time_zone: 'UTC',
      },
      end: {
        date_time: @end_time.to_datetime.rfc3339,
        time_zone: 'UTC',
      }
    )

    result = @service.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Event created: \
#{result.html_link}")
    result.id
  rescue Google::Apis::Error => e
    error_message = "An error occurred: \
#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def authorize
    FileUtils.mkdir_p(File.dirname(CREDENTIALS_PATH))

    client_id = Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the resulting code after authorization:\n\n"
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end
end
