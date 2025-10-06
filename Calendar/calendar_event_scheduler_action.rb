require 'google/apis/calendar_v3'
require 'googleauth'
require 'outlook_calendar'

# Description: Sublayer::Action responsible for creating or modifying events in a calendar (Google Calendar, Outlook)
# integrating AI scheduling suggestions into personal or organizational calendars.
# This action allows for the automation of event scheduling based on AI insights.
#
# Example usage: When you want to automatically schedule a meeting or event based on availability suggestions from AI.

class CalendarEventSchedulerAction < Sublayer::Actions::Base
  def initialize(service:, credentials:, calendar_id:, event_details:)
    @service = service
    @credentials = credentials
    @calendar_id = calendar_id
    @event_details = event_details
    @client = initialize_client
  end

  def call
    case @service
    when 'google'
      schedule_google_event
    when 'outlook'
      schedule_outlook_event
    else
      raise StandardError, "Unsupported calendar service: #@service"
    end
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error scheduling calendar event: #{e.message}")
    raise e
  end

  private

  def initialize_client
    case @service
    when 'google'
      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(@credentials),
        scope: Google::Apis::CalendarV3::AUTH_CALENDAR
      )
      service
    when 'outlook'
      OutlookCalendar.new(client_id: @credentials[:client_id],
                          client_secret: @credentials[:client_secret],
                          tenant_id: @credentials[:tenant_id])
    end
  end

  def schedule_google_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @event_details[:summary],
      start: { date_time: @event_details[:start_time].rfc3339 },
      end: { date_time: @event_details[:end_time].rfc3339 }
    )

    result = @client.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Google Calendar event created: #{result.id}")
    result.id
  end

  def schedule_outlook_event
    event = {
      'subject' => @event_details[:summary],
      'start' => {
        'dateTime' => @event_details[:start_time].iso8601,
        'timeZone' => 'UTC'
      },
      'end' => {
        'dateTime' => @event_details[:end_time].iso8601,
        'timeZone' => 'UTC'
      }
    }

    result = @client.create_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Outlook Calendar event created: #{result.id}")
    result.id
  end
end
