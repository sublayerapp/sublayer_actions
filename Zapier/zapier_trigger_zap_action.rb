require 'zapier_ruby'

# Description: Sublayer::Action to trigger a specific Zap in Zapier.
# This action allows for seamless integration between Sublayer workflows and Zapier, enabling automation of various tasks.
#
# Requires: `zapier_ruby` gem
# \$ gem install zapier_ruby
# Or
# add `gem \"zapier_ruby\"` to your Gemfile
# and add `requires \"zapier_ruby\"` somewhere in your app.
#
# It is initialized with a webhook_url and payload (data to be sent to Zapier).
# It returns the HTTP response to confirm the Zap was triggered successfully.
#
# Example usage: When you want to trigger a specific action in Zapier based on an event or data generated in your Sublayer workflow.

class ZapierTriggerZapAction < Sublayer::Actions::Base
  def initialize(webhook_url:, payload: {})
    @webhook_url = webhook_url
    @payload = payload
  end

  def call
    begin
      response = ZapierRuby::Hook.new(hook_url: @webhook_url).execute(@payload)

      if response.success?
        Sublayer.configuration.logger.log(:info, "Zap triggered successfully with response: \#{response.body}\")
        response.body
      else
        error_message = "Error triggering Zap: \#{response.body}\"
        Sublayer.configuration.logger.log(:error, error_message)
        raise StandardError, error_message
      end
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error triggering Zap: \#{e.message}\")
      raise e
    end
  end
end
