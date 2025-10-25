require 'jwt'
require 'http'

# Description: Sublayer::Action responsible for retrieving and processing Zoom meeting transcripts.
# This action fetches the transcript of a specified Zoom meeting and formats it for use in LLM prompts.
#
# Required Environment Variables:
# - ZOOM_ACCOUNT_ID: Your Zoom account ID
# - ZOOM_CLIENT_ID: Your Zoom client ID
# - ZOOM_CLIENT_SECRET: Your Zoom client secret
#
# It is initialized with a meeting_id and returns the formatted transcript text.
#
# Example usage: When you want to analyze meeting transcripts with an LLM to generate
# summaries, extract action items, or create follow-up tasks.

class ZoomMeetingTranscriptAction < Sublayer::Actions::Base
  def initialize(meeting_id:)
    @meeting_id = meeting_id
    @account_id = ENV['ZOOM_ACCOUNT_ID']
    @client_id = ENV['ZOOM_CLIENT_ID']
    @client_secret = ENV['ZOOM_CLIENT_SECRET']
  end

  def call
    begin
      access_token = generate_access_token
      transcript_files = fetch_transcript_files(access_token)
      
      if transcript_files.empty?
        error_message = "No transcript found for meeting #{@meeting_id}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end

      transcript_content = fetch_transcript_content(access_token, transcript_files.first['download_url'])
      format_transcript(transcript_content)
    rescue StandardError => e
      error_message = "Error retrieving Zoom transcript: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def generate_access_token
    payload = {
      iss: @client_id,
      exp: Time.now.to_i + 3600
    }

    token = JWT.encode(payload, @client_secret, 'HS256')

    response = HTTP.post(
      'https://zoom.us/oauth/token',
      form: {
        grant_type: 'account_credentials',
        account_id: @account_id
      },
      headers: {
        'Authorization' => "Basic #{Base64.strict_encode64("#{@client_id}:#{@client_secret}")}"
      }
    )

    unless response.status.success?
      raise StandardError, "Failed to obtain access token: #{response.body}"
    end

    JSON.parse(response.body)['access_token']
  end

  def fetch_transcript_files(access_token)
    response = HTTP
      .auth("Bearer #{access_token}")
      .get("https://api.zoom.us/v2/meetings/#{@meeting_id}/recordings")

    unless response.status.success?
      raise StandardError, "Failed to fetch recording info: #{response.body}"
    end

    JSON.parse(response.body)['recording_files'].select { |file| file['recording_type'] == 'transcript' }
  end

  def fetch_transcript_content(access_token, download_url)
    response = HTTP
      .auth("Bearer #{access_token}")
      .get(download_url)

    unless response.status.success?
      raise StandardError, "Failed to download transcript: #{response.body}"
    end

    response.body.to_s
  end

  def format_transcript(content)
    # Parse the VTT format and convert to a more readable text format
    lines = content.split("\n")
    formatted_lines = []
    current_speaker = nil
    current_text = ""

    lines.each do |line|
      if line.match?(/^[0-9]{2}:[0-9]{2}:[0-9]{2}/)
        next # Skip timestamp lines
      elsif line.match?(/^[^\n]+: /)
        # New speaker line
        if current_speaker && !current_text.empty?
          formatted_lines << "#{current_speaker}: #{current_text.strip}"
          current_text = ""
        end
        current_speaker = line.split(":").first
        current_text = line.split(":")[1..-1].join(":").strip
      elsif !line.strip.empty?
        current_text += " #{line.strip}"
      end
    end

    # Add the last segment if exists
    if current_speaker && !current_text.empty?
      formatted_lines << "#{current_speaker}: #{current_text.strip}"
    end

    formatted_lines.join("\n")
  end
end