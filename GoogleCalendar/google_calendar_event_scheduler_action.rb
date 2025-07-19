require 'google/apis/calendar_v3'

# Description: Sublayer::Action responsible for creating and managing events in Google Calendar.
# Initialized with event details like title, start_time, end_time, and participants.
#
# Example usage: When you want to schedule meetings or events programmatically, using data generated
# by an LLM or through another automated process.

class GoogleCalendarEventSchedulerAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_title:, start_time:, end_time:, participants: [], **kwargs)
    super(**kwargs)
    @calendar_id = calendar_id
    @event_title = event_title
    @start_time = start_time
    @end_time = end_time
    @participants = participants
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = ENV['GOOGLE_API_TOKEN']
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @event_title,
      start: { date_time: @start_time, time_zone: 'UTC' },
      end: { date_time: @end_time, time_zone: 'UTC' },
      attendees: format_participants
    )

    @service.insert_event(@calendar_id, event)

    Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar: #{@event_title}")
  rescue Google::Apis::ServerError => e
    error_message = "Server error during event creation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue Google::Apis::ClientError => e
    error_message = "Client error during event creation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Unexpected error during event creation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def format_participants
    @participants.map do |participant|
      { email: participant }
    end
  end
end