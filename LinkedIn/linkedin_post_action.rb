require 'oauth2'
require 'json'

# Description: Sublayer::Action responsible for posting content to LinkedIn via their API.
# This action enables automated posting of professional updates, articles, or LLM-generated insights
# while maintaining control over the posting process through LinkedIn's official API.
#
# Requires: 'oauth2' gem
# $ gem install oauth2
# Or add `gem 'oauth2'` to your Gemfile
#
# It is initialized with the post content and optional parameters for customizing the post.
# Returns the post ID (URN) if successful.
#
# Example usage: When you want to automatically publish AI-generated professional content,
# market insights, or company updates to LinkedIn as part of an automated content workflow.

class LinkedInPostAction < Sublayer::Actions::Base
  BASE_URL = 'https://api.linkedin.com/v2'

  def initialize(content:, visibility: 'PUBLIC', media_url: nil, title: nil)
    @content = content
    @visibility = visibility # Can be 'PUBLIC', 'CONNECTIONS', or 'CONTAINER'
    @media_url = media_url
    @title = title
    @access_token = ENV['LINKEDIN_ACCESS_TOKEN']
    @author = ENV['LINKEDIN_AUTHOR_URN'] # The URN of the user or organization posting
  end

  def call
    begin
      client = create_client
      response = post_to_linkedin(client)
      
      post_id = response['id']
      Sublayer.configuration.logger.log(:info, "Successfully posted content to LinkedIn with ID: #{post_id}")
      post_id
    rescue OAuth2::Error => e
      error_message = "LinkedIn API authentication error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error posting to LinkedIn: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def create_client
    OAuth2::Client.new(
      ENV['LINKEDIN_CLIENT_ID'],
      ENV['LINKEDIN_CLIENT_SECRET'],
      site: BASE_URL
    )
  end

  def post_to_linkedin(client)
    access_token = OAuth2::AccessToken.new(client, @access_token)
    
    payload = build_payload
    
    response = access_token.post(
      "#{BASE_URL}/ugcPosts",
      body: payload.to_json,
      headers: {
        'Content-Type' => 'application/json',
        'X-Restli-Protocol-Version' => '2.0.0'
      }
    )

    JSON.parse(response.body)
  end

  def build_payload
    payload = {
      'author': @author,
      'lifecycleState': 'PUBLISHED',
      'specificContent': {
        'com.linkedin.ugc.ShareContent': {
          'shareCommentary': {
            'text': @content
          },
          'shareMediaCategory': @media_url ? 'IMAGE' : 'NONE'
        }
      },
      'visibility': {
        'com.linkedin.ugc.MemberNetworkVisibility': @visibility
      }
    }

    # Add media if provided
    if @media_url
      payload[:specificContent][:'com.linkedin.ugc.ShareContent'][:media] = [
        {
          'status': 'READY',
          'media': @media_url,
          'title': {
            'text': @title || 'Image'
          }
        }
      ]
    end

    payload
  end
end