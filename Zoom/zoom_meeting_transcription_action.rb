require 'jwt'
require 'net/http'
require 'json'

# Description: Sublayer::Action responsible for fetching and processing Zoom meeting transcriptions.
# This action retrieves the audio transcript of a specific Zoom meeting using the Zoom API,
# making it available for AI analysis, summaries, or action item generation.
#
# Requires: 'jwt' gem for JWT token generation
# $ gem install jwt
# Or add `gem 'jwt'` to your Gemfile
#
# It is initialized with a meeting_id and optionally returns_json (default: false).
# It returns either a plain text transcription or a JSON structure with timestamped entries.
#
# Environment variables required:
# - ZOOM_API_KEY: Your Zoom API Key
# - ZOOM_API_SECRET: Your Zoom API Secret
#
# Example usage: When you want to analyze the content of a Zoom meeting for generating
# summaries, action items, or other AI-driven insights.

class ZoomMeetingTranscriptionAction < Sublayer::Actions::Base
  def initialize(meeting_id:, returns_json: false)
    @meeting_id = meeting_id
    @returns_json = returns_json
    @api_key = ENV['ZOOM_API_KEY']
    @api_secret = ENV['ZOOM_API_SECRET']
  end

  def call
    begin
      validate_credentials!
      transcription = fetch_transcription
      process_transcription(transcription)
    rescue StandardError => e
      error_message = "Error fetching Zoom transcription: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_credentials!
    unless @api_key && @api_secret
      raise StandardError, 'Missing Zoom API credentials. Please set ZOOM_API_KEY and ZOOM_API_SECRET environment variables.'
    end
  end

  def generate_jwt_token
    payload = {
      iss: @api_key,
      exp: Time.now.to_i + 4 * 60 # Token expires in 4 minutes
    }

    JWT.encode(payload, @api_secret, 'HS256')
  end

  def fetch_transcription
    uri = URI.parse("https://api.zoom.us/v2/meetings/#{@meeting_id}/recordings")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = "Bearer #{generate_jwt_token}"
    request['Content-Type'] = 'application/json'

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      error_message = "Failed to fetch transcription. HTTP Response Code: #{response.code}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    JSON.parse(response.body)
  end

  def process_transcription(raw_transcription)
    # Find the transcription file from the recording files
    transcript_file = raw_transcription['recording_files'].find { |f| f['recording_type'] == 'audio_transcript' }
    
    unless transcript_file
      error_message = 'No transcription file found for this meeting'
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end

    # Download the actual transcription content
    download_url = transcript_file['download_url']
    uri = URI.parse(download_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Authorization'] = "Bearer #{generate_jwt_token}"
    response = http.request(request)

    transcription_content = JSON.parse(response.body)

    if @returns_json
      Sublayer.configuration.logger.log(:info, "Successfully retrieved JSON transcription for meeting #{@meeting_id}")
      transcription_content
    else
      # Convert to plain text, combining all speaker segments
      plain_text = transcription_content['messages'].map do |msg|
        "#{msg['speaker']}: #{msg['text']}"
      end.join("\n")

      Sublayer.configuration.logger.log(:info, "Successfully retrieved plain text transcription for meeting #{@meeting_id}")
      plain_text
    end
  end
end