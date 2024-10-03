class NotionCreateRowAction < Sublayer::Actions::Base
  def initialize(database_id:, properties:)
    @database_id = database_id
    @properties = properties
  end

  def call
    notion = Notion::Client.new(token: ENV['NOTION_API_KEY'])

    notion.create_page(
      parent: {
        database_id: @database_id
      },
      properties: @properties
    )
  end
end
