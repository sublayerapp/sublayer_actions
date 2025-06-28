require 'aws-sdk-transcribeservice'

# Description: Sublayer::Action responsible for transcribing audio files using AWS Transcribe service.
# This action takes an audio file URL as input and returns the transcribed text.
#
# Requires: 'aws-sdk-transcribeservice' gem
# $ gem install aws-sdk-transcribeservice
# Or add `gem 'aws-sdk-transcribeservice'` to your Gemfile
#
# It is initialized with the URL of the audio file and optional parameters for transcription.
# It returns the transcribed text from the audio file.
#
# Example usage: When you want to convert speech to text for further AI analysis,
# such as sentiment analysis or content processing.

class AWSTranscribeAudioAction < Sublayer::Actions::Base
  def initialize(audio_url:, language_code: 'en-US', job_name: nil)
    @audio_url = audio_url
    @language_code = language_code
    @job_name = job_name || "transcription-#{Time.now.to_i}"
    
    @client = Aws::TranscribeService::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )
  end

  def call
    begin
      start_transcription_job
      wait_for_completion
      get_transcription_text
    rescue Aws::TranscribeService::Errors::ServiceError => e
      error_message = "AWS Transcribe error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error during transcription: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def start_transcription_job
    @client.start_transcription_job({
      transcription_job_name: @job_name,
      media: { media_file_uri: @audio_url },
      media_format: detect_media_format,
      language_code: @language_code
    })
    
    Sublayer.configuration.logger.log(:info, "Started transcription job: #{@job_name}")
  end

  def wait_for_completion
    loop do
      response = @client.get_transcription_job({
        transcription_job_name: @job_name
      })

      status = response.transcription_job.transcription_job_status
      
      case status
      when 'COMPLETED'
        Sublayer.configuration.logger.log(:info, "Transcription job completed: #{@job_name}")
        @transcript_url = response.transcription_job.transcript.transcript_file_uri
        break
      when 'FAILED'
        error_message = "Transcription job failed: #{response.transcription_job.failure_reason}"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      else
        sleep 5  # Wait 5 seconds before checking again
      end
    end
  end

  def get_transcription_text
    require 'open-uri'
    require 'json'

    transcript_json = URI.open(@transcript_url).read
    transcript_data = JSON.parse(transcript_json)
    
    transcript_data['results']['transcripts'].first['transcript']
  end

  def detect_media_format
    case File.extname(@audio_url).downcase
    when '.mp3'
      'mp3'
    when '.mp4'
      'mp4'
    when '.wav'
      'wav'
    when '.flac'
      'flac'
    else
      error_message = "Unsupported audio format: #{File.extname(@audio_url)}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end