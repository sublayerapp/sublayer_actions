# Description: Sublayer::Action to interact with Google Calendar. This action allows for creating, updating, and deleting events, as well as querying for events based on various criteria.

require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'date'
require 'fileutils'

class GoogleCalendarAction < Sublayer::Actions::Base
  def initialize(action:, calendar_id: 'primary', event_id: nil, summary: nil, description: nil, start_time: nil, end_time: nil, time_zone: nil, attendees: nil, query_params: nil )
    @action = action
    @calendar_id = calendar_id
    @event_id = event_id
    @summary = summary
    @description = description
    @start_time = start_time
    @end_time = end_time
    @time_zone = time_zone || 'America/Los_Angeles' # Defaulting to a common time zone but it'd be better to pull this from config or context
    @attendees = attendees
    @query_params = query_params

    # Path to client_secret.json and token storage
    @client_secrets_path = 'path/to/client_secret.json'
    @credentials_path = 'path/to/token.yaml' 
    @scopes = [Google::Apis::CalendarV3::AUTH_CALENDAR]

    @service = get_calendar_service
  end

  def call
    case @action
    when 'create'
      create_event
    when 'update'
      update_event
    when 'delete'
      delete_event
    when 'get'
      get_event
    when 'query'
      query_events
    else
      raise ArgumentError, "Invalid action: #{@action}"
    end
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error in GoogleCalendarAction: #{e.message}")
    raise e
  end

  private

  def create_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time, time_zone: @time_zone),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time, time_zone: @time_zone),
      attendees: @attendees
    )
    @service.insert_event(@calendar_id, event)
  end

  def update_event
    event = @service.get_event(@calendar_id, @event_id)
    event.summary = @summary if @summary
    event.description = @description if @description
    event.start = Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time, time_zone: @time_zone) if @start_time
    event.end = Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time, time_zone: @time_zone) if @end_time
    event.attendees = @attendees if @attendees
    @service.update_event(@calendar_id, @event_id, event)
  end

  def delete_event
    @service.delete_event(@calendar_id, @event_id)
  end

  def get_event
    @service.get_event(@calendar_id, @event_id)
  end

  def query_events
    response = @service.list_events(@calendar_id, @query_params)
    response.items
  end


  def authorize
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(@client_secrets_path),
      scope: @scopes
    )
  end

  def get_calendar_service
    service = Google::Apis::CalendarV3::CalendarService.new
    service.client_options.application_name = 'Sublayer Calendar Action'
    service.authorization = authorize
    service
  end
end