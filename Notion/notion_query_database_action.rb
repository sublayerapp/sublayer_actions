class NotionQueryDatabaseAction < Sublayer::Actions::Base
  def initialize(database_id:, filter: {}, sorts: [])
    @database_id = database_id
    @filter = filter
    @sorts = sorts
  end

  def call
    notion = Notion::Client.new(token: ENV['NOTION_API_KEY'])

    begin
      response = notion.database_query(
        database_id: @database_id,
        filter: @filter.empty? ? nil : @filter,
        sorts: @sorts.empty? ? nil : @sorts
      )

      response[:results]
    rescue StandardError => e
      logger.error "Error querying Notion database: #{e.message}"
      raise e
    end
  end
end