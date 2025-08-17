require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar based on task due dates or project milestones from other services.
#
# It is initialized with a calendar_id, event_summary, start_time, end_time, and optional description and location.
# It returns the ID of the created event.
#
# Example usage: When you want to automatically schedule events in Google Calendar based on tasks or milestones identified in Asana or Jira.

class GoogleCalendarEventCreatorAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_summary:, start_time:, end_time:, description: nil, location: nil)
    @calendar_id = calendar_id
    @event_summary = event_summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @location = location

    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = 'Sublayer AI'
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"]) 
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @event_summary,
      location: @location,
      description: @description,
      start: {
        date_time: @start_time,
        time_zone: 'UTC',
      },
      end: {
        date_time: @end_time,
        time_zone: 'UTC',
      }
    )

    begin
      created_event = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: \\#{created_event.id}")
      created_event.id
    rescue Google::Apis::ClientError => e
      error_message = "Error creating Google Calendar event: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "General error: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end