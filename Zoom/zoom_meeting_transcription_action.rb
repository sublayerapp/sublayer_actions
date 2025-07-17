require 'jwt'
require 'http'

# Description: Sublayer::Action responsible for retrieving and processing Zoom meeting transcripts.
# This action fetches the transcript of a specified Zoom meeting and converts it into structured text,
# making it suitable for AI analysis, summarization, or action item extraction.
#
# Requires:
# - Zoom JWT App credentials (API_KEY and API_SECRET)
# - Meeting ID of a cloud-recorded meeting with transcript enabled
#
# It is initialized with a meeting_id and returns the processed transcript text.
# The transcript includes speaker attribution and timestamps.
#
# Example usage: When you want to analyze meeting content with an LLM to generate
# summaries, extract action items, or perform other text analysis on meeting transcripts.

class ZoomMeetingTranscriptionAction < Sublayer::Actions::Base
  def initialize(meeting_id:)
    @meeting_id = meeting_id
    @api_key = ENV['ZOOM_API_KEY']
    @api_secret = ENV['ZOOM_API_SECRET']
    @base_url = 'https://api.zoom.us/v2'
  end

  def call
    begin
      recording_info = fetch_recording_info
      transcript_url = extract_transcript_url(recording_info)
      transcript_content = download_transcript(transcript_url)
      processed_transcript = process_transcript(transcript_content)

      Sublayer.configuration.logger.log(:info, "Successfully processed transcript for meeting #{@meeting_id}")
      processed_transcript
    rescue StandardError => e
      error_message = "Error processing Zoom transcript: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def generate_jwt_token
    payload = {
      iss: @api_key,
      exp: Time.now.to_i + 120 # Token expires in 2 minutes
    }

    JWT.encode(payload, @api_secret, 'HS256')
  end

  def fetch_recording_info
    response = HTTP
      .headers(authorization: "Bearer #{generate_jwt_token}")
      .get("#{@base_url}/meetings/#{@meeting_id}/recordings")

    unless response.status.success?
      raise StandardError, "Failed to fetch recording info: #{response.status}"
    end

    JSON.parse(response.body.to_s)
  end

  def extract_transcript_url(recording_info)
    transcript_file = recording_info['recording_files'].find { |file| file['recording_type'] == 'audio_transcript' }
    
    unless transcript_file && transcript_file['download_url']
      raise StandardError, 'No transcript found for this meeting'
    end

    transcript_file['download_url']
  end

  def download_transcript(url)
    response = HTTP
      .headers(authorization: "Bearer #{generate_jwt_token}")
      .get(url)

    unless response.status.success?
      raise StandardError, "Failed to download transcript: #{response.status}"
    end

    response.body.to_s
  end

  def process_transcript(content)
    # Parse the VTT format and convert to structured text
    # Remove VTT headers and metadata
    lines = content.split("\n").drop(2)
    
    transcript = []
    current_entry = {}

    lines.each do |line|
      case line
      when /^(\d{2}:\d{2}:\d{2}\.\d{3}) --> (\d{2}:\d{2}:\d{2}\.\d{3})$/
        # New timestamp entry
        transcript << current_entry unless current_entry.empty?
        current_entry = { timestamp: $1 }
      when /^([^\n]+): (.+)$/
        # Speaker and text
        current_entry[:speaker] = $1
        current_entry[:text] = $2.strip
      when ''
        # Skip empty lines
        next
      else
        # Additional text from the same speaker
        current_entry[:text] = "#{current_entry[:text]} #{line}".strip if current_entry[:text]
      end
    end

    transcript << current_entry unless current_entry.empty?

    # Format the transcript into a readable string
    transcript.map do |entry|
      "[#{entry[:timestamp]}] #{entry[:speaker]}: #{entry[:text]}"
    end.join("\n")
  end
end