require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in a Google Calendar.
# This action allows for integration with Google Calendar to automate scheduling tasks.
#
# Requires: 'google-api-client' gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# It is initialized with calendar_id, summary, start_time, end_time, and optional description.
# It returns the ID of the created event as confirmation.
#
# Example usage: When you want to create a Google Calendar event based on AI-generated scheduling insights.

class GoogleCalendarEventCreationAction < Sublayer::Actions::Base
  def initialize(calendar_id:, summary:, start_time:, end_time:, description: nil, **kwargs)
    @calendar_id = calendar_id
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = 'Sublayer App'
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/calendar"])
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      start: {
        date_time: @start_time
      },
      end: {
        date_time: @end_time
      }
    )
    
    begin
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar: \\#{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end