require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables easy integration of speech-to-text capabilities into Sublayer workflows,
# making it possible to process audio content before sending it to other LLM-based generators.
#
# Requires: 'openai' gem
# $ gem install openai
# Or add `gem 'openai'` to your Gemfile
#
# It is initialized with an audio file path and optional parameters for language and response format.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to transcribe audio content for further analysis or processing
# by other Sublayer::Generators.

class OpenAISpeechToTextAction < Sublayer::Actions::Base
  def initialize(audio_file_path:, language: nil, response_format: 'text')
    @audio_file_path = audio_file_path
    @language = language
    @response_format = response_format
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      validate_file
      response = transcribe_audio
      
      Sublayer.configuration.logger.log(:info, "Successfully transcribed audio file: #{@audio_file_path}")
      
      if @response_format == 'json'
        response['text']
      else
        response
      end
    rescue StandardError => e
      error_message = "Error transcribing audio: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def validate_file
    unless File.exist?(@audio_file_path)
      raise StandardError, "Audio file does not exist: #{@audio_file_path}"
    end

    unless valid_audio_format?
      raise StandardError, "Invalid audio format. Supported formats: mp3, mp4, mpeg, mpga, m4a, wav, or webm"
    end
  end

  def valid_audio_format?
    valid_extensions = %w[.mp3 .mp4 .mpeg .mpga .m4a .wav .webm]
    valid_extensions.include?(File.extname(@audio_file_path).downcase)
  end

  def transcribe_audio
    audio_file = File.open(@audio_file_path, 'rb')
    
    params = {
      model: 'whisper-1',
      file: audio_file,
      response_format: @response_format
    }
    
    params[:language] = @language if @language
    
    @client.audio.transcribe(parameters: params)
  ensure
    audio_file&.close
  end
end