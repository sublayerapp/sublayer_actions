# Description: Sublayer::Action to interact with Google Calendar API. This action allows creating, updating, and deleting events, as well as checking for conflicts and free/busy times.

# Example usage:  Create a calendar event for when you expect a response to a prompt

require 'google/apis/calendar_v3'

class GoogleCalendarAction < Sublayer::Actions::Base
  def initialize(action:, calendar_id: 'primary', event_data: nil, event_id: nil, start_time: nil, end_time: nil)
    @action = action
    @calendar_id = calendar_id
    @event_data = event_data
    @event_id = event_id
    @start_time = start_time
    @end_time = end_time

    @service = Google::Apis::CalendarV3::CalendarService.new
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
      when 'check_conflicts'
        check_conflicts
      when 'get_free_busy'
        get_free_busy
      else
        raise ArgumentError, "Invalid action: #{@action}"
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Google Calendar Action failed: #{e.message}")
      raise e
    end
  end

  private

  def create_event
    event = Google::Apis::CalendarV3::Event.new(@event_data)
    @service.insert_event(@calendar_id, event)
  end

  def update_event
    event = @service.get_event(@calendar_id, @event_id)
    event.update!(@event_data)
    @service.update_event(@calendar_id, @event_id, event)
  end

  def delete_event
    @service.delete_event(@calendar_id, @event_id)
  end

  def check_conflicts
    events = @service.list_events(@calendar_id, time_min: @start_time, time_max: @end_time)
    events.items.present?
  end

  def get_free_busy
    query = Google::Apis::CalendarV3::FreeBusyRequest.new(
      time_min: @start_time,
      time_max: @end_time,
      items: [{ id: @calendar_id }]
    )
    result = @service.query_freebusy(query)
    result.calendars[@calendar_id].busy
  end
end