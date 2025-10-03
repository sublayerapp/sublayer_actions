require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files using OpenAI's Whisper API.
# This action enables audio content to be converted to text for use in LLM prompts or further analysis.
#
# It is initialized with either a local file path or a URL to an audio file.
# It returns the transcribed text of the audio content.
#
# Supported file formats: mp3, mp4, mpeg, mpga, m4a, wav, or webm
# Maximum file size: 25 MB
#
# Example usage: When you want to process audio content from recordings, meetings, or voice notes
# and use the transcribed text in your Sublayer workflow.

class OpenAITranscribeAudioAction < Sublayer::Actions::Base
  def initialize(file_path: nil, file_url: nil)
    raise ArgumentError, 'Either file_path or file_url must be provided' if file_path.nil? && file_url.nil?
    raise ArgumentError, 'Only one of file_path or file_url should be provided' if file_path && file_url
    
    @file_path = file_path
    @file_url = file_url
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      response = if @file_path
                  transcribe_local_file
                else
                  transcribe_remote_file
                end

      Sublayer.configuration.logger.log(:info, 'Audio transcription completed successfully')
      response['text']
    rescue OpenAI::Error => e
      error_message = "OpenAI API error during transcription: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during audio transcription: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def transcribe_local_file
    unless File.exist?(@file_path)
      raise StandardError, "Audio file not found at: #{@file_path}"
    end

    file = File.open(@file_path)
    @client.audio.transcribe(
      parameters: {
        model: 'whisper-1',
        file: file
      }
    )
  ensure
    file&.close
  end

  def transcribe_remote_file
    response = download_file(@file_url)
    
    @client.audio.transcribe(
      parameters: {
        model: 'whisper-1',
        file: StringIO.new(response.body)
      }
    )
  end

  def download_file(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    
    unless response.is_a?(Net::HTTPSuccess)
      raise StandardError, "Failed to download audio file from URL: #{url}. Status: #{response.code}"
    end
    
    response
  end
end