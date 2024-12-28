require 'speech_to_text_api'

# Description: Sublayer::Action responsible for processing voice commands using a speech-to-text API.
# This action transcribes the voice command and triggers corresponding actions within a workflow or system.
#
# It is initialized with audio_data and optional parameters for configuration.
# It returns the text transcription of the voice command and any subsequent actions triggered.
#
# Example usage: When you have voice commands that need to be transcribed and processed in a Sublayer workflow.

class VoiceCommandProcessingAction < Sublayer::Actions::Base
  def initialize(audio_data:, config: {})
    @audio_data = audio_data
    @config = config
    @client = SpeechToTextAPI::Client.new(api_key: ENV['SPEECH_TO_TEXT_API_KEY'])
  end

  def call
    begin
      transcript = transcribe_audio
      triggered_actions = process_transcript(transcript)
      Sublayer.configuration.logger.log(:info, "Voice command processed successfully")
      { transcript: transcript, triggered_actions: triggered_actions }
    rescue StandardError => e
      error_message = "Error processing voice command: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def transcribe_audio
    response = @client.transcribe(audio: @audio_data, config: @config)
    raise "Transcription failed" unless response.success?

    response.transcript
  end

  def process_transcript(transcript)
    # Logic to process the transcribed text and trigger actions in the system
    # For simplicity, we'll just log and return an empty array here
    Sublayer.configuration.logger.log(:info, "Processing transcript: #{transcript}")
    []
  end
end
