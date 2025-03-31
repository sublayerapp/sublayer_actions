# Description: Sublayer::Action responsible for scheduling events on Calendly.
# This action allows for seamless integration with Calendly to automate appointment scheduling, ideal for AI-driven schedule management.
#
# It is initialized with event details like event_type, start_time, and guests.
# It returns the link to the created Calendly event.
#
# Example usage: When you want to automatically schedule an event in Calendly based on AI-generated schedules or user requests.

require 'calendly'

class CalendlyEventCreationAction < Sublayer::Actions::Base
  def initialize(event_type:, start_time:, guests: [])
    @event_type = event_type
    @start_time = start_time
    @guests = guests
    @client = Calendly::Client.new(token: ENV['CALENDLY_API_KEY'])
  end

  def call
    begin
      event = create_event
      Sublayer.configuration.logger.log(:info, "Calendly event created successfully: #{event.uri}")
      event.uri
    rescue Calendly::Error => e
      error_message = "Error creating Calendly event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_event
    @client.event_types.create_event(
      event_type: @event_type,
      start_time: @start_time,
      invitees: format_guests(@guests)
    )
  end

  def format_guests(guests)
    guests.map { |guest| { email: guest } }
  end
end