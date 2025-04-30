# Description: Sublayer::Action for interacting with the Google Calendar API.
# This action allows users to create, update, and delete events, as well as query for existing events.

require 'google/apis/calendar_v3'

class GoogleCalendarAction < Sublayer::Actions::Base
  def initialize(action:, calendar_id: 'primary', event_id: nil, event_details: {})
    @action = action
    @calendar_id = calendar_id
    @event_id = event_id
    @event_details = event_details

    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = 'Sublayer Calendar Action'
    @service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/calendar'])
  end

  def call
    begin
      case @action
      when 'create'
        create_event
      when 'update'
        update_event
      when 'delete'
        delete_event
      when 'get'
        get_event
      else
        raise ArgumentError, "Invalid action: #{@action}. Valid actions are: create, update, delete, get"
      end
    rescue Google::Apis::Error => e
      error_message = "Error interacting with Google Calendar: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_event
    event = Google::Apis::CalendarV3::Event.new(@event_details)
    @service.insert_event(@calendar_id, event)
  end

  def update_event
    event = @service.get_event(@calendar_id, @event_id)
    event.update!(@event_details)
    @service.update_event(@calendar_id, @event_id, event)
  end

  def delete_event
    @service.delete_event(@calendar_id, @event_id)
  end

  def get_event
    @service.get_event(@calendar_id, @event_id)
  end
end