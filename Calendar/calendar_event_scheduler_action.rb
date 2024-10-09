require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action can be used to automate scheduling tasks by creating events
# programmatically based on inputs received from other parts of your Sublayer workflow.
#
# It is initialized with a calendar_id, event details (start_time, end_time, summary, etc.),
# and returns the event ID to verify it was created successfully.

class CalendarEventSchedulerAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_details:)
    @calendar_id = calendar_id
    @event_details = event_details
    authorize
  end

  def call
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = @credentials

    begin
      event = Google::Apis::CalendarV3::Event.new(@event_details)
      result = service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully: #{result.id}")
      result.id
    rescue Google::Apis::ClientError => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def authorize
    scopes = ['https://www.googleapis.com/auth/calendar']
    @credentials = Google::Auth.get_application_default(scopes)
    Sublayer.configuration.logger.log(:info, 'Google Calendar API authorization successful')
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Authorization error: #{e.message}")
    raise e
  end
end
