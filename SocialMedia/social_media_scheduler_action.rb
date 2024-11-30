require 'twitter'
require 'koala'

# Description: Sublayer::Action responsible for scheduling posts to various social media platforms like Twitter and Facebook.
# It allows easy integration for scheduling posts as part of a Sublayer workflow.
#
# This action is initialized with platform-specific tokens, a message, and a scheduled time for the post.
# It supports multiple platforms and logs the outcomes of each posting operation.
#
# Example usage: When you want to automate posting to social media platforms as part of an AI-driven content strategy.

class SocialMediaSchedulerAction < Sublayer::Actions::Base
  def initialize(twitter_credentials: {}, facebook_credentials: {}, message:, scheduled_time: Time.now)
    @twitter_credentials = twitter_credentials
    @facebook_credentials = facebook_credentials
    @message = message
    @scheduled_time = scheduled_time
  end

  def call
    post_to_twitter if @twitter_credentials.any?
    post_to_facebook if @facebook_credentials.any?
  end

  private

  def post_to_twitter
    begin
      client = Twitter::REST::Client.new do |config|
        config.consumer_key        = @twitter_credentials[:consumer_key]
        config.consumer_secret     = @twitter_credentials[:consumer_secret]
        config.access_token        = @twitter_credentials[:access_token]
        config.access_token_secret = @twitter_credentials[:access_token_secret]
      end

      if Time.now >= @scheduled_time
        client.update(@message)
        Sublayer.configuration.logger.log(:info, "Message posted to Twitter at \\#{Time.now}")
      else
        Sublayer.configuration.logger.log(:info, "Scheduled Twitter post not yet due.")
      end
    rescue Twitter::Error => e
      Sublayer.configuration.logger.log(:error, "Twitter Error: \\#{e.message}")
      raise StandardError, "Error posting to Twitter: \\#{e.message}"
    end
  end

  def post_to_facebook
    begin
      graph = Koala::Facebook::API.new(@facebook_credentials[:access_token])
      page_id = @facebook_credentials[:page_id]

      if Time.now >= @scheduled_time
        graph.put_object(page_id, 'feed', message: @message)
        Sublayer.configuration.logger.log(:info, "Message posted to Facebook at \\#{Time.now}")
      else
        Sublayer.configuration.logger.log(:info, "Scheduled Facebook post not yet due.")
      end
    rescue Koala::Facebook::APIError => e
      Sublayer.configuration.logger.log(:error, "Facebook Error: \\#{e.message}")
      raise StandardError, "Error posting to Facebook: \\#{e.message}"
    end
  end
end