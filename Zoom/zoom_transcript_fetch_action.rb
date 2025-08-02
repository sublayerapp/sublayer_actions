require 'httparty'

# Description: Sublayer::Action responsible for fetching transcripts from Zoom meetings using the Zoom API.
# This action allows for retrieving transcription content from recorded Zoom meetings, which can be used
# for AI processing, meeting summarization, or other text analysis tasks.
#
# Requires: 'httparty' gem
# $ gem install httparty
# Or add `gem 'httparty'` to your Gemfile
#
# It is initialized with a meeting_id and optionally a recording_id.
# It returns the transcript content as a string.
#
# Example usage: When you want to process or analyze the content of a Zoom meeting using AI,
# such as generating meeting summaries or extracting action items.

class ZoomTranscriptFetchAction < Sublayer::Actions::Base
  include HTTParty
  base_uri 'https://api.zoom.us/v2'

  def initialize(meeting_id:, recording_id: nil)
    @meeting_id = meeting_id
    @recording_id = recording_id
    @jwt_token = ENV['ZOOM_JWT_TOKEN']
    raise StandardError, 'ZOOM_JWT_TOKEN environment variable not set' unless @jwt_token
  end

  def call
    begin
      recording_id = @recording_id || fetch_latest_recording_id
      transcript = fetch_transcript(recording_id)
      
      Sublayer.configuration.logger.log(:info, "Successfully fetched transcript for meeting #{@meeting_id}")
      transcript
    rescue StandardError => e
      error_message = "Error fetching Zoom transcript: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def fetch_latest_recording_id
    url = "/meetings/#{@meeting_id}/recordings"
    response = self.class.get(url, headers: auth_headers)

    if response.success?
      recordings = response['recording_files'].select { |r| r['recording_type'] == 'transcript' }
      raise StandardError, 'No transcript found for this meeting' if recordings.empty?
      
      recordings.sort_by { |r| r['recording_start'] }.last['id']
    else
      handle_error_response(response)
    end
  end

  def fetch_transcript(recording_id)
    url = "/meetings/#{@meeting_id}/recordings/#{recording_id}/transcript"
    response = self.class.get(url, headers: auth_headers)

    if response.success?
      parse_transcript(response.body)
    else
      handle_error_response(response)
    end
  end

  def parse_transcript(transcript_data)
    # Parse the transcript data based on Zoom's format
    # This might need adjustment based on the actual format returned by Zoom
    JSON.parse(transcript_data)['messages'].map do |message|
      "[#{message['timestamp']}] #{message['speaker']}: #{message['text']}"
    end.join("\n")
  end

  def auth_headers
    {
      'Authorization' => "Bearer #{@jwt_token}",
      'Content-Type' => 'application/json'
    }
  end

  def handle_error_response(response)
    error_message = "Zoom API error: #{response.code} - #{response.body}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end