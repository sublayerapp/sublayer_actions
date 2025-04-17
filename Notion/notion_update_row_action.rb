# Description: Sublayer::Action responsible for updating properties of an existing row in a Notion database.
#
# It is initialized with a page_id and the updated properties. It updates the row and maintains current and accurate data.
#
# Example usage: Useful for workflows needing to modify existing data entries in Notion databases.

class NotionUpdateRowAction < Sublayer::Actions::Base
  def initialize(page_id:, properties:)
    @page_id = page_id
    @properties = properties
  end

  def call
    notion = Notion::Client.new(token: ENV['NOTION_API_KEY'])
    
    begin
      notion.update_page(
        page_id: @page_id,
        properties: @properties
      )
      puts "Successfully updated the page with ID: #{@page_id}"
    rescue StandardError => e
      puts "Error updating the page: #{e.message}"
      # Additional logging can be added here
    end
  end
end
