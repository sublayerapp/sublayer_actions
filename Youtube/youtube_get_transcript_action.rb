require 'yt_transcript' 

# Description: Sublayer::Action responsible for transcribing a YouTube video given its URL.
# This action leverages the 'yt_transcript' gem for interacting with the YouTube Transcript API.
#
# Requires: 'yt_transcript' gem
# $ gem install yt_transcript
# Or add `gem 'yt_transcript'` to your Gemfile
#
# It is initialized with a youtube_video_url.
# It returns the transcript of the video as a string.
#
# Example usage: When you want to transcribe a YouTube video as part of an AI-driven workflow
class YoutubeGetTranscriptAction < Sublayer::Actions::Base
  def initialize(youtube_video_url:)
    @youtube_video_url = youtube_video_url
  end

  def call
    begin
      transcript = YtTranscript.fetch(@youtube_video_url)
      Sublayer.configuration.logger.log(:info, "Successfully transcribed YouTube video: #{@youtube_video_url}")
      transcript
    rescue YtTranscript::Error => e
      error_message = "Error transcribing YouTube video: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end