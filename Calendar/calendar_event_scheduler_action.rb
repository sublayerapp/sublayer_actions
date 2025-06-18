require 'google/apis/calendar_v3'
require 'googleauth'
require 'outlook_calendar_service'

# Description: Sublayer::Action responsible for creating an event in either Google or Outlook calendar.
# This action simplifies scheduling tasks and reminders, making it easier for various agents to coordinate and manage events.

class CalendarEventSchedulerAction < Sublayer::Actions::Base
  def initialize(service_type:, event_details:)
    @service_type = service_type.downcase
    @event_details = event_details
    initialize_service
  end

  def call
    begin
      case @service_type
      when 'google'
        create_google_event
      when 'outlook'
        create_outlook_event
      else
        raise "Unsupported calendar service: #{@service_type}"
      end
      Sublayer.configuration.logger.log(:info, "Event created successfully in #{@service_type} calendar.")
    rescue StandardError => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_service
    case @service_type
    when 'google'
      @service = Google::Apis::CalendarV3::CalendarService.new
      @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])
    when 'outlook'
      @service = OutlookCalendarService.new(ENV['OUTLOOK_CLIENT_ID'], ENV['OUTLOOK_CLIENT_SECRET'], ENV['OUTLOOK_REFRESH_TOKEN'])
    end
  end

  def create_google_event
    event = Google::Apis::CalendarV3::Event.new(@event_details)
    @service.insert_event('primary', event)
  end

  def create_outlook_event
    @service.create_event(@event_details)
  end
end