require 'openai'
require 'google/cloud/speech'

# Description: Sublayer::Action responsible for transcribing audio files to text using either OpenAI's Whisper API
# or Google Cloud Speech-to-Text service. This action enables the processing of audio content for use in text-based
# AI workflows.
#
# It is initialized with an audio file path and optionally the service to use (whisper or google).
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content for analysis by an LLM or to generate responses
# based on spoken content.

class TranscribeAudioFileAction < Sublayer::Actions::Base
  SUPPORTED_SERVICES = ['whisper', 'google']
  SUPPORTED_FORMATS = ['.mp3', '.mp4', '.mpeg', '.mpga', '.m4a', '.wav', '.webm']

  def initialize(audio_file_path:, service: 'whisper', language: 'en')
    @audio_file_path = audio_file_path
    @service = service.downcase
    @language = language

    raise ArgumentError, "Service must be one of: #{SUPPORTED_SERVICES.join(', ')}" unless SUPPORTED_SERVICES.include?(@service)
    raise ArgumentError, 'Audio file path cannot be empty' if @audio_file_path.nil? || @audio_file_path.empty?
    raise ArgumentError, "Unsupported audio format. Supported formats: #{SUPPORTED_FORMATS.join(', ')}" unless SUPPORTED_FORMATS.include?(File.extname(@audio_file_path).downcase)
    raise ArgumentError, 'Audio file does not exist' unless File.exist?(@audio_file_path)
  end

  def call
    begin
      transcription = case @service
                     when 'whisper'
                       transcribe_with_whisper
                     when 'google'
                       transcribe_with_google
                     end

      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file using #{@service}")
      transcription
    rescue StandardError => e
      error_message = "Error transcribing audio file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def transcribe_with_whisper
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
    
    response = client.audio.transcribe(
      parameters: {
        model: 'whisper-1',
        file: File.open(@audio_file_path, 'rb'),
        language: @language
      }
    )

    response['text']
  end

  def transcribe_with_google
    client = Google::Cloud::Speech.speech

    config = {
      language_code: @language,
      encoding: :LINEAR16,
      sample_rate_hertz: 16000
    }

    audio = { uri: @audio_file_path }
    operation = client.long_running_recognize(config: config, audio: audio)
    operation.wait_until_done!

    raise operation.error if operation.error?

    results = operation.response.results
    results.map { |result| result.alternatives.first.transcript }.join(" ")
  end
end