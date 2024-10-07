require 'google/apis/calendar_v3'
require 'googleauth'

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, description:, start_time:, end_time:, attendees: [], time_zone: 'UTC')
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @time_zone = time_zone
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: 'https://www.googleapis.com/auth/calendar'
    )
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @start_time.to_datetime.rfc3339,
        time_zone: @time_zone
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @end_time.to_datetime.rfc3339,
        time_zone: @time_zone
      ),
      attendees: @attendees.map { |email| { email: email } }
    )

    begin
      result = @service.insert_event('primary', event)
      Sublayer.configuration.logger.log(:info, "Event created: #{result.html_link}")
      result.id
    rescue Google::Apis::Error => e
      Sublayer.configuration.logger.log(:error, "Error creating Google Calendar event: #{e.message}")
      raise e
    end
  end
end