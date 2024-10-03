require 'notion-ruby-client'
require 'csv'

class NotionSyncWithExternalSourceAction < Sublayer::Actions::Base
  def initialize(database_id:, external_source:, mapping:)
    @database_id = database_id
    @external_source = external_source
    @mapping = mapping
    @notion_client = Notion::Client.new(token: ENV['NOTION_API_KEY'])
  end

  def call
    external_data = fetch_external_data
    notion_data = fetch_notion_data

    sync_data(external_data, notion_data)
  end

  private

  def fetch_external_data
    case @external_source[:type]
    when 'csv'
      fetch_csv_data
    when 'api'
      fetch_api_data
    else
      raise ArgumentError, "Unsupported external source type: #{@external_source[:type]}"
    end
  end

  def fetch_csv_data
    CSV.read(@external_source[:path], headers: true).map(&:to_h)
  end

  def fetch_api_data
    # Implement API data fetching logic here
    # This is a placeholder and should be replaced with actual API call
    raise NotImplementedError, 'API data fetching is not implemented yet'
  end

  def fetch_notion_data
    results = []
    has_more = true
    start_cursor = nil

    while has_more
      response = @notion_client.database_query(
        database_id: @database_id,
        start_cursor: start_cursor
      )

      results += response.results
      has_more = response.has_more
      start_cursor = response.next_cursor
    end

    results
  end

  def sync_data(external_data, notion_data)
    external_data.each do |external_item|
      notion_item = find_matching_notion_item(external_item, notion_data)

      if notion_item
        update_notion_item(notion_item, external_item)
      else
        create_notion_item(external_item)
      end
    end
  end

  def find_matching_notion_item(external_item, notion_data)
    notion_data.find do |notion_item|
      @mapping[:key_field].all? do |ext_key, notion_key|
        external_item[ext_key.to_s] == notion_item.properties[notion_key]['rich_text'][0]['text']['content']
      end
    end
  end

  def update_notion_item(notion_item, external_item)
    properties = build_properties(external_item)
    @notion_client.update_page(page_id: notion_item.id, properties: properties)
  rescue Notion::ApiError => e
    log_error("Failed to update Notion item: #{e.message}")
  end

  def create_notion_item(external_item)
    properties = build_properties(external_item)
    @notion_client.create_page(parent: { database_id: @database_id }, properties: properties)
  rescue Notion::ApiError => e
    log_error("Failed to create Notion item: #{e.message}")
  end

  def build_properties(external_item)
    @mapping[:fields].transform_values do |notion_field|
      {
        type: notion_field[:type],
        notion_field[:type] => { content: external_item[notion_field[:external_field].to_s] }
      }
    end
  end

  def log_error(message)
    # Implement your logging logic here
    puts "Error: #{message}"
  end
end
