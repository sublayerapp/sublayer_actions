require 'google/cloud/speech'

# Description: Sublayer::Action responsible for transcribing audio or video files into text using Google Cloud Speech-to-Text.
# This action allows seamless integration of audio/video data into AI workflows,
# enabling transcription, analysis, summarization, and other actions based on the transcribed content.
#
# It is initialized with a gcs_uri or file_path to the audio/video file.
# It returns the transcribed text.
#
# Example usage: When you want to transcribe audio/video content for use in an AI-driven workflow or analysis.

class GoogleCloudSpeechToTextAction < Sublayer::Actions::Base
  def initialize(gcs_uri: nil, file_path: nil, language_code: 'en-US')
    @gcs_uri = gcs_uri
    @file_path = file_path
    @language_code = language_code
    @client = Google::Cloud::Speech.speech
  end

  def call
    begin
      audio = determine_audio_source

      config = {
        language_code: @language_code
      }
      response = @client.recognize(config, audio)

      transcript = response.results.map(&:alternatives).flatten.map(&:transcript).join(' ')

      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio/video content")

      transcript
    rescue Google::Cloud::Error => e
      error_message = "Error transcribing audio/video: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def determine_audio_source
    if @gcs_uri
      { uri: @gcs_uri }
    elsif @file_path
      { content: File.read(@file_path) }
    else
      raise ArgumentError, "Either gcs_uri or file_path must be provided"
    end
  end
end