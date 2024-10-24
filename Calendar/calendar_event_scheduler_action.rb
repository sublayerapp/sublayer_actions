require 'google/apis/calendar_v3'
require 'microsoft_graph'

# Description: Sublayer::Action responsible for scheduling a new event in either Google Calendar or Microsoft Outlook.
# It integrates with both services and checks available time slots to schedule meetings based on provided descriptions.
#
# Requires: 'google-api-client' gem for Google Calendar and 'microsoft_graph' gem for Microsoft Outlook
#
# It is initialized with service (either :google or :outlook), credentials, event details such as summary, start_time, end_time, and attendees.
# It returns the event ID to confirm successful scheduling.
#
# Example usage: When an AI agent needs to set up meetings across different calendar platforms after evaluating potential time slots.

class CalendarEventSchedulerAction < Sublayer::Actions::Base
  def initialize(service:, credentials:, summary:, start_time:, end_time:, attendees: [], description: nil)
    @service = service
    @credentials = credentials
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @description = description
    setup_client
  end

  def call
    case @service
    when :google
      schedule_google_event
    when :outlook
      schedule_outlook_event
    else
      raise ArgumentError, "Unsupported service provider"
    end
  end

  private

  def setup_client
    case @service
    when :google
      @client = Google::Apis::CalendarV3::CalendarService.new
      @client.authorization = @credentials
    when :outlook
      @client = MicrosoftGraph.new(client_id: ENV['MICROSOFT_CLIENT_ID'],
                                  client_secret: ENV['MICROSOFT_CLIENT_SECRET'],
                                  tenant: ENV['MICROSOFT_TENANT'])
      @client.auth_parameters = { token: @credentials }
    end
  end

  def schedule_google_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      start: { date_time: @start_time.rfc3339 },
      end: { date_time: @end_time.rfc3339 },
      attendees: @attendees.map { |email| { email: email } },
      description: @description
    )
    result = @client.insert_event('primary', event)
    Sublayer.configuration.logger.log(:info, "Scheduled Google Calendar event #{result.id}")
    result.id
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error scheduling Google event: #{e.message}")
    raise e
  end

  def schedule_outlook_event
    event = {
      "subject" => @summary,
      "body" => { "contentType" => "HTML", "content" => @description },
      "start" => { "dateTime" => @start_time.iso8601, "timeZone" => "UTC" },
      "end" => { "dateTime" => @end_time.iso8601, "timeZone" => "UTC" },
      "attendees" => @attendees.map { |email| { "emailAddress" => { "address" => email }, "type" => "required" } }
    }
    result = @client.me.events.create(event)
    Sublayer.configuration.logger.log(:info, "Scheduled Outlook Calendar event #{result['id']}")
    result['id']
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error scheduling Outlook event: #{e.message}")
    raise e
  end
end