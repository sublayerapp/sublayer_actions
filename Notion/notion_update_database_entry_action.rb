# Description: Sublayer::Action responsible for updating specific properties of a database entry in Notion using its ID.
# This action enables dynamic content management and automation within the Notion workspace.
#
# Requires: 'notion_ruby_client' gem
# $ gem install notion_ruby_client
# Or add `gem 'notion_ruby_client'` to your Gemfile
#
# It is initialized with a page_id and properties to update.
# It returns the updated page's ID confirming the update.
#
# Example usage: When you want to update details of a Notion page dynamically as part of an AI-driven process.

class NotionUpdateDatabaseEntryAction < Sublayer::Actions::Base
  def initialize(page_id:, properties:)
    @page_id = page_id
    @properties = properties
    @client = Notion::Client.new(token: ENV['NOTION_API_KEY'])
  end

  def call
    begin
      response = @client.update_page(
        page_id: @page_id,
        properties: @properties
      )

      # Log successful update
      Sublayer.configuration.logger.log(:info, "Notion page updated successfully: #{@page_id}")

      response.id
    rescue StandardError => e
      error_message = "Error updating Notion database entry: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end