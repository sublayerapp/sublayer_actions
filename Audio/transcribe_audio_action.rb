require 'aws-sdk-transcribeservice'
require 'openai'

# Description: Sublayer::Action responsible for transcribing audio files to text using either
# AWS Transcribe or OpenAI's Whisper API.
#
# It is initialized with an audio file path and optionally a service choice (aws or whisper).
# It returns the transcribed text from the audio file.
#
# Supported audio formats:
# - AWS Transcribe: mp3, mp4, wav, flac
# - Whisper API: mp3, mp4, mpeg, mpga, m4a, wav, webm
#
# Example usage: When you want to convert audio content to text for processing through
# text-based AI generators or analysis.

class TranscribeAudioAction < Sublayer::Actions::Base
  def initialize(audio_path:, service: :whisper)
    @audio_path = audio_path
    @service = service.to_sym
    
    unless File.exist?(@audio_path)
      raise ArgumentError, "Audio file not found at #{@audio_path}"
    end
    
    unless [:aws, :whisper].include?(@service)
      raise ArgumentError, "Invalid service. Must be :aws or :whisper"
    end
  end

  def call
    case @service
    when :aws
      transcribe_with_aws
    when :whisper
      transcribe_with_whisper
    end
  rescue StandardError => e
    error_message = "Error transcribing audio: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def transcribe_with_aws
    client = Aws::TranscribeService::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )

    job_name = "transcription-#{Time.now.to_i}"
    s3_uri = upload_to_s3(@audio_path)

    response = client.start_transcription_job({
      transcription_job_name: job_name,
      media: { media_file_uri: s3_uri },
      media_format: File.extname(@audio_path)[1..-1],
      language_code: 'en-US'
    })

    # Poll for completion
    loop do
      job = client.get_transcription_job({
        transcription_job_name: job_name
      })

      break if job.transcription_job.transcription_job_status == 'COMPLETED'
      
      if job.transcription_job.transcription_job_status == 'FAILED'
        raise StandardError, job.transcription_job.failure_reason
      end

      sleep(5)
    end

    # Get the transcript
    transcript_uri = job.transcription_job.transcript.transcript_file_uri
    transcript_response = URI.open(transcript_uri).read
    JSON.parse(transcript_response)['results']['transcripts'][0]['transcript']
  end

  def transcribe_with_whisper
    client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])

    response = client.audio.transcribe(
      parameters: {
        model: 'whisper-1',
        file: File.open(@audio_path)
      }
    )

    response['text']
  end

  def upload_to_s3(file_path)
    # This method would handle uploading the audio file to S3
    # Implementation would depend on your S3 bucket configuration
    # Returns the S3 URI of the uploaded file
    s3_client = Aws::S3::Client.new(
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      region: ENV['AWS_REGION']
    )

    bucket = ENV['AWS_S3_BUCKET']
    key = "audio-transcription/#{File.basename(file_path)}"

    s3_client.put_object(
      bucket: bucket,
      key: key,
      body: File.read(file_path)
    )

    "s3://#{bucket}/#{key}"
  end
end