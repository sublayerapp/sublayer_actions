require 'google/apis/calendar_v3'
require 'googleauth'
require 'outlook/calendar_v3'

# Description: Sublayer::Action responsible for creating a new event in Google Calendar or Microsoft Outlook Calendar.
# This action can be used to schedule events based on input details like event name, time, and participants.
#
# Example usage: When you want to automate the scheduling of meetings or events based on information from an LLM or other sources.

class CalendarEventCreationAction < Sublayer::Actions::Base
  def initialize(service:, event_name:, start_time:, end_time:, participants: [], description: nil)
    @service = service.downcase
    @event_name = event_name
    @start_time = start_time
    @end_time = end_time
    @participants = participants
    @description = description
    configure_calendar_client
  end

  def call
    case @service
    when 'google'
      create_google_event
    when 'outlook'
      create_outlook_event
    else
      raise StandardError, "Unsupported calendar service: #{@service}"
    end
  rescue StandardError => e
    error_message = "Error creating calendar event: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def configure_calendar_client
    case @service
    when 'google'
      configure_google_client
    when 'outlook'
      configure_outlook_client
    end
  end

  def configure_google_client
    @google_client = Google::Apis::CalendarV3::CalendarService.new
    @google_client.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/calendar'])
  end

  def configure_outlook_client
    @outlook_client = Outlook::CalendarV3::Client.new(
      token: ENV['OUTLOOK_ACCESS_TOKEN']
    )
  end

  def create_google_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @event_name,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time),
      attendees: @participants.map { |email| {email: email} },
      description: @description
    )
    @google_client.insert_event('primary', event)
    Sublayer.configuration.logger.log(:info, "Google Calendar event created: #{@event_name}")
  end

  def create_outlook_event
    event = {
      'subject' => @event_name,
      'start' => {
        'dateTime' => @start_time,
        'timeZone' => 'UTC'
      },
      'end' => {
        'dateTime' => @end_time,
        'timeZone' => 'UTC'
      },
      'attendees' => @participants.map { |email| {'emailAddress' => {'address' => email}} },
      'body' => {
        'contentType' => 'HTML',
        'content' => @description
      }
    }
    @outlook_client.create_event(event)
    Sublayer.configuration.logger.log(:info, "Outlook Calendar event created: #{@event_name}")
  end
end
