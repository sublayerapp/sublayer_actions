# google_calendar_event_creator_action.rb

require 'sublayer'
require 'google/apis/calendar_v3'
require 'googleauth'

module Actions
  class GoogleCalendarEventCreator < Sublayer::Actions::Base
    def initialize(event_title:, event_start_time:, event_end_time:, calendar_id: 'primary', description: nil, location: nil, attendees: [])
      @event_title = event_title
      @event_start_time = event_start_time
      @event_end_time = event_end_time
      @calendar_id = calendar_id
      @description = description
      @location = location
      @attendees = attendees
    end

    def call
      service = Google::Apis::CalendarV3::CalendarService.new
      service.client_options.application_name = 'Sublayer Google Calendar Event Creator'
      service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/calendar'])

      event = Google::Apis::CalendarV3::Event.new(
        summary: @event_title,
        location: @location,
        description: @description,
        start: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: @event_start_time
        ),
        end: Google::Apis::CalendarV3::EventDateTime.new(
          date_time: @event_end_time
        ),
        attendees: @attendees.map { |email| { email: email } }
      )

      begin
        result = service.insert_event(@calendar_id, event)
        logger.info "Event created: #{result.html_link}"
      rescue Google::Apis::Error => e
        logger.error "An error occurred: #{e.message}"
        raise "Failed to create the event due to an error: #{e.message}"
      end
    end

    private

    def logger
      @logger ||= Logger.new(STDOUT)
    end
  end
end
