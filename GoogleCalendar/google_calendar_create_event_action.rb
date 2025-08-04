require 'google/apis/calendar_v3'

# Description: Sublayer::Action responsible for creating a new event in Google Calendar.
# This action integrates with Google Calendar using the Google API Client.
#
# It is initialized with event details such as title, date, time, and participants.
# It returns the ID of the created event.
#
# Example usage: When you want to schedule a meeting or event based on LLM-generated insights or reminders.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(summary:, start_time:, end_time:, attendees: [], **kwargs)
    super(**kwargs)
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @calendar = Google::Apis::CalendarV3::CalendarService.new
    @calendar.authorization = authorize
  end

  def call
    begin
      event = create_event
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{event.id}")
      event.id
    rescue Google::Apis::ClientError => e
      error_message = "Google Calendar API returned an error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def authorize
    # This is where you should handle authorization with Google APIs
    # This sample assumes the OAuth2 client settings are read from environment variables or a credential file
    ENV['GOOGLE_API_AUTHORIZATION']
  end

  def create_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      start: { date_time: @start_time },
      end: { date_time: @end_time },
      attendees: @attendees.map { |email| { email: email } }
    )

    @calendar.insert_event('primary', event)
  end
end