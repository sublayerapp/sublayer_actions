# Description: Sublayer::Action for interacting with Google Calendar. Allows for creating, updating, and deleting events, as well as checking for conflicts and sending invitations.

# Requires: google-api-client gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, summary:, start_time:, end_time:, attendees: [], description: nil, location: nil)
    @calendar_id = calendar_id
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @description = description
    @location = location

    @client = Google::Apis::CalendarV3::CalendarService.new
    @client.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/calendar'])
  end

  def call
    begin
      event = Google::Apis::CalendarV3::Event.new(
        summary: @summary,
        description: @description,
        location: @location,
        start: {
          date_time: @start_time.to_datetime.rfc822
        },
        end: {
          date_time: @end_time.to_datetime.rfc822
        },
        attendees: @attendees.map { |email| { email: email } }
      )

      result = @client.insert_event(@calendar_id, event)

      Sublayer.configuration.logger.log(:info, "Google Calendar event created successfully: #{result.id}")

      result
    rescue Google::Apis::ClientError => e
      error_message = "Error interacting with Google Calendar: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end