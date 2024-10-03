# Description: Sublayer::Action responsible for updating specific rows within a Notion database.
# It is initialized with a database_id, a filter to find the rows to update, and the properties to update.
# This complements the NotionQueryDatabaseAction and allows dynamic data management.

class NotionDatabaseUpdateAction < Sublayer::Actions::Base
  def initialize(database_id:, filter:, properties:)
    @database_id = database_id
    @filter = filter
    @properties = properties
  end

  def call
    notion = Notion::Client.new(token: ENV['NOTION_API_KEY'])

    begin
      # Query the database to find rows that match the filter
      query_results = notion.query_database(
        database_id: @database_id,
        filter: @filter
      )

      # Update each row with the provided properties
      query_results[:results].each do |row|
        notion.update_page(
          page_id: row[:id],
          properties: @properties
        )
      end

    rescue StandardError => e
      logger.error "Error updating Notion database rows: #{e.message}"
      raise e
    end
  end
end
