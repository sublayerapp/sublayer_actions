require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action integrates with Google Calendar API to create calendar events with
# support for attendees, description, and automatic Google Meet link generation.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# The action requires a Google Cloud project with Calendar API enabled and
# appropriate credentials configured via environment variables.
#
# It is initialized with event details including title, start_time, end_time,
# and optional parameters for attendees, description, and video conferencing.
#
# Example usage: When you want to automatically schedule meetings based on
# AI analysis of conversations or documents.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(
    title:,
    start_time:,
    end_time:,
    attendees: [],
    description: nil,
    add_meet_link: false,
    calendar_id: 'primary'
  )
    @title = title
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @description = description
    @add_meet_link = add_meet_link
    @calendar_id = calendar_id
    setup_client
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(
        :info,
        "Created calendar event '#{@title}' with ID: #{result.id}"
      )
      
      result
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_client
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: StringIO.new(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: 'https://www.googleapis.com/auth/calendar'
    )
  end

  def create_event_object
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: Time.zone.name
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: Time.zone.name
      }
    )

    if @attendees.any?
      event.attendees = @attendees.map { |email| { email: email } }
    end

    if @add_meet_link
      event.conference_data = {
        create_request: {
          request_id: SecureRandom.uuid,
          conference_solution_key: { type: 'hangoutsMeet' }
        }
      }
    end

    event
  end
end