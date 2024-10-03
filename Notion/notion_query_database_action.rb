class NotionQueryDatabaseAction < Sublayer::Actions::Base
  def initialize(database_id:, filter: {}, sorts: [])
    @database_id = database_id
    @filter = filter
    @sorts = sorts
  end

  def call
    notion = Notion::Client.new(token: ENV['NOTION_API_KEY'])

    begin
      params = { database_id: @database_id }
      params[:filter] = @filter unless @filter.empty?
      params[:sorts] = @sorts unless @sorts.empty?
      
      response = notion.database_query(query)

      response[:results]
    rescue StandardError => e
      logger.error "Error querying Notion database: #{e.message}"
      raise e
    end
  end
end
