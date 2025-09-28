class NotionUpdatePagePropertiesAction < Sublayer::Actions::Base
  def initialize(page_id:, properties:)
    @page_id = page_id
    @properties = properties
  end

  def call
    notion = Notion::Client.new(token: ENV['NOTION_API_KEY'])

    begin
      response = notion.update_page_properties(page_id: @page_id, properties: @properties)
      Sublayer.configuration.logger.log(:info, "Successfully updated properties for Notion page #{@page_id}")
      response
    rescue StandardError => e
      error_message = "Error updating Notion page properties: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
