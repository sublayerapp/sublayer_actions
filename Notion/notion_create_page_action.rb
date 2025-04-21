# Description: Sublayer::Action responsible for creating a new page in a Notion database with specified properties.
# It is initialized with a database_id and properties, and returns the ID of the newly created page.
#
# Example usage: When you want to add a new entry to a Notion database based on the results of an AI workflow or user input.

class NotionCreatePageAction < Sublayer::Actions::Base
  def initialize(database_id:, properties:)
    @database_id = database_id
    @properties = properties
  end

  def call
    notion = Notion::Client.new(token: ENV['NOTION_API_KEY'])

    begin
      response = notion.create_page(
        parent: { database_id: @database_id },
        properties: @properties
      )

      # Return the ID of the newly created page
      response['id']
    rescue StandardError => e
      logger.error "Error creating Notion page: #{e.message}"
      raise e
    end
  end
end