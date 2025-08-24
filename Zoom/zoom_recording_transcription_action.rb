require 'httparty'
require 'tempfile'
require 'openai'

# Description: Sublayer::Action responsible for fetching a Zoom cloud recording and generating
# a transcript using OpenAI's Whisper API. This action integrates with both Zoom's API to
# download recordings and OpenAI's Whisper API for transcription.
#
# It is initialized with a recording_id and returns the generated transcript text.
#
# Example usage: When you want to process meeting recordings for analysis by AI models,
# create searchable meeting archives, or generate meeting summaries.
#
# Required Environment Variables:
# - ZOOM_JWT_TOKEN: Your Zoom JWT token for API access
# - OPENAI_API_KEY: Your OpenAI API key for Whisper access

class ZoomRecordingTranscriptionAction < Sublayer::Actions::Base
  include HTTParty
  base_uri 'https://api.zoom.us/v2'

  def initialize(recording_id:)
    @recording_id = recording_id
    @zoom_token = ENV['ZOOM_JWT_TOKEN']
    @openai_client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      recording_info = fetch_recording_info
      audio_file = download_recording(recording_info)
      transcript = generate_transcript(audio_file)
      
      Sublayer.configuration.logger.log(:info, 'Successfully transcribed Zoom recording')
      transcript
    rescue StandardError => e
      error_message = "Error processing Zoom recording: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      # Clean up temporary files
      audio_file&.close
      audio_file&.unlink
    end
  end

  private

  def fetch_recording_info
    options = {
      headers: {
        'Authorization' => "Bearer #{@zoom_token}",
        'Content-Type' => 'application/json'
      }
    }

    response = self.class.get("/recordings/#{@recording_id}", options)
    
    unless response.success?
      raise StandardError, "Failed to fetch recording info: #{response.code} - #{response.message}"
    end

    recording_files = response['recording_files']
    audio_recording = recording_files.find { |file| file['file_type'] == 'M4A' }
    
    unless audio_recording
      raise StandardError, 'No audio recording found in Zoom cloud recording'
    end

    audio_recording
  end

  def download_recording(recording_info)
    download_url = recording_info['download_url']
    
    options = {
      headers: {
        'Authorization' => "Bearer #{@zoom_token}"
      }
    }

    temp_file = Tempfile.new(['zoom_recording', '.m4a'])
    
    response = HTTParty.get(download_url, options)
    unless response.success?
      temp_file.close
      temp_file.unlink
      raise StandardError, "Failed to download recording: #{response.code} - #{response.message}"
    end

    temp_file.binmode
    temp_file.write(response.body)
    temp_file.rewind
    
    temp_file
  end

  def generate_transcript(audio_file)
    response = @openai_client.audio.transcribe(
      parameters: {
        model: 'whisper-1',
        file: audio_file
      }
    )

    unless response['text']
      raise StandardError, 'Failed to generate transcript from audio'
    end

    response['text']
  end
end