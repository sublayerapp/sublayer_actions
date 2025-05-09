require 'aws-sdk-polly'

# Description: Sublayer::Action responsible for converting text to speech using Amazon Polly.
# This action allows for easy text-to-speech conversion within a Sublayer workflow,
# enabling the creation of audio content from AI-generated or other text sources.
#
# It is initialized with the text to convert, desired voice ID, and optional output format.
# On successful execution, it returns the path to the generated audio file.
#
# Example usage: When you want to create an audio version of AI-generated text for accessibility or content creation.

class TextToSpeechConversionAction < Sublayer::Actions::Base
  def initialize(text:, voice_id: 'Joanna', output_format: 'mp3', output_path: './output.mp3')
    @text = text
    @voice_id = voice_id
    @output_format = output_format
    @output_path = output_path
    @client = Aws::Polly::Client.new(
      region: ENV['AWS_REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def call
    begin
      response = @client.synthesize_speech({
        output_format: @output_format,
        text: @text,
        voice_id: @voice_id
      })

      IO.copy_stream(response.audio_stream, @output_path)

      Sublayer.configuration.logger.log(:info, "Successfully converted text to speech: #{@output_path}")
      @output_path
    rescue Aws::Polly::Errors::ServiceError => e
      error_message = "Error converting text to speech: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
