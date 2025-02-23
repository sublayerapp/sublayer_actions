require 'zoom_rb'

# Description: Sublayer::Action responsible for scheduling a Zoom meeting
# and sending invitations based on task completion or specific prompts.
# This action facilitates seamless meeting organization by integrating
# with the Zoom API.
#
# Requires: `zoom_rb` gem
# $ gem install zoom_rb
# Or add `gem 'zoom_rb'` to your Gemfile
#
# It is initialized with topic, start_time, duration (in minutes), and invitees,
# and returns the meeting details including the join URL.
#
# Example usage: When an AI process determines a necessary meeting schedule
# after completing tasks, this action can automatically set up the meeting
# and notify participants.

class ZoomScheduleMeetingAction < Sublayer::Actions::Base
  def initialize(topic:, start_time:, duration:, invitees: [])
    @topic = topic
    @start_time = start_time
    @duration = duration
    @invitees = invitees
    @client = Zoom::Client::OAuth.new(access_token: ENV['ZOOM_ACCESS_TOKEN'])
  end

  def call
    begin
      meeting = create_meeting
      Sublayer.configuration.logger.log(:info, "Zoom meeting scheduled successfully: #{meeting['id']}")

      invite_participants(meeting['join_url'])

      meeting
    rescue Zoom::Error => e
      error_message = "Error scheduling Zoom meeting: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_meeting
    @client.meeting_create(user: "me",
                           topic: @topic,
                           start_time: @start_time,
                           duration: @duration,
                           settings: { join_before_host: true })
  end

  def invite_participants(join_url)
    @invitees.each do |email|
      # Simulate sending an email invitation
      Sublayer.configuration.logger.log(:info, "Invitation sent to #{email} with join URL: #{join_url}")
    end
  end
end
