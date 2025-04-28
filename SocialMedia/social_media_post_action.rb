require 'twitter'
require 'koala'
require 'linkedin-ruby'

# Description: Sublayer::Action responsible for posting content to social media platforms like Twitter, Facebook, and LinkedIn.
# This action automates the broadcasting of AI-generated insights or updates to these platforms.
#
# It is initialized with a platform, content, and optional additional parameters specific to each platform.
# It returns a confirmation message or ID of the post to confirm it was posted successfully.
#
# Example usage: When you want to automatically share AI-generated insights on social media platforms.

class SocialMediaPostAction < Sublayer::Actions::Base
  def initialize(platform:, content:, **kwargs)
    @platform = platform
    @content = content
    @kwargs = kwargs
  end

  def call
    case @platform.downcase
    when 'twitter'
      post_to_twitter
    when 'facebook'
      post_to_facebook
    when 'linkedin'
      post_to_linkedin
    else
      raise ArgumentError, "Unsupported platform: \\#{@platform}"
    end
  end

  private

  def post_to_twitter
    client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV['TWITTER_CONSUMER_KEY']
      config.consumer_secret     = ENV['TWITTER_CONSUMER_SECRET']
      config.access_token        = ENV['TWITTER_ACCESS_TOKEN']
      config.access_token_secret = ENV['TWITTER_ACCESS_SECRET']
    end

    begin
      tweet = client.update(@content)
      Sublayer.configuration.logger.log(:info, "Successfully posted to Twitter: \\#{tweet.uri}")
      tweet.id
    rescue Twitter::Error => e
      Sublayer.configuration.logger.log(:error, "Twitter error: \\#{e.message}")
      raise e
    end
  end

  def post_to_facebook
    graph = Koala::Facebook::API.new(ENV['FACEBOOK_ACCESS_TOKEN'])
    begin
      post = graph.put_connections('me', 'feed', message: @content)
      Sublayer.configuration.logger.log(:info, "Successfully posted to Facebook with post ID: \\#{post['id']}")
      post['id']
    rescue Koala::Facebook::APIError => e
      Sublayer.configuration.logger.log(:error, "Facebook API error: \\#{e.message}")
      raise e
    end
  end

  def post_to_linkedin
    client = LinkedIn::Client.new(ENV['LINKEDIN_CLIENT_ID'], ENV['LINKEDIN_CLIENT_SECRET'])
    client.authorize_from_access(ENV['LINKEDIN_ACCESS_TOKEN'])

    begin
      post = client.add_share(comment: @content)
      Sublayer.configuration.logger.log(:info, "Successfully posted to LinkedIn")
      post['updateKey']
    rescue LinkedIn::Errors::Error => e
      Sublayer.configuration.logger.log(:error, "LinkedIn error: \\#{e.message}")
      raise e
    end
  end
end