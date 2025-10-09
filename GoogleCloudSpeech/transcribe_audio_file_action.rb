require 'google/cloud/speech'

# Description: Sublayer::Action responsible for transcribing audio files into text using Google Cloud Speech-to-Text.
# This action is useful for converting voice notes or meetings into text for further analysis.
#
# It is initialized with an audio_file_path and locale. It returns the transcribed text.
#
# Example usage: Use this action to transcribe recorded meetings or voice notes into text form for analysis using LLMs or other tools.

class TranscribeAudioFileAction < Sublayer::Actions::Base
  def initialize(audio_file_path:, locale: 'en-US')
    @audio_file_path = audio_file_path
    @locale = locale
    @client = Google::Cloud::Speech.speech
  end

  def call
    begin
      transcribe_audio
    rescue Google::Cloud::Error => e
      error_message = "Error during audio transcription: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def transcribe_audio
    # Read the audio file
    audio_file = File.binread(@audio_file_path)

    # Configure the audio
    config = { encoding: :LINEAR16, sample_rate_hertz: 16_000, language_code: @locale }
    audio  = { content: audio_file }

    # Perform the transcription
    response = @client.recognize(config: config, audio: audio)
    results = response.results

    # Collect the transcriptions
    transcriptions = results.map(&:alternatives).flatten.map(&:transcript)
    transcribed_text = transcriptions.join("\n")

    Sublayer.configuration.logger.log(:info, "Transcription successful for #{@audio_file_path}")

    transcribed_text
  end
end