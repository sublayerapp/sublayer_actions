require 'airrecord'

# Description: Sublayer::Action responsible for upserting (update if exists, create if doesn't) a record in an Airtable base.
# This action allows for maintaining databases with AI-generated or processed content by automatically handling
# the create/update logic based on a specified unique field.
#
# Requires: 'airrecord' gem
# $ gem install airrecord
# Or add `gem 'airrecord'` to your Gemfile
#
# It is initialized with:
# - base_id: The Airtable base ID
# - table_name: The name of the table in the base
# - fields: Hash of field names and values to upsert
# - unique_field: The field name to use for checking existence (e.g., 'Email' or 'ID')
#
# Returns the ID of the created or updated record.
#
# Example usage: When you want to maintain a database of AI-processed content,
# ensuring no duplicates while keeping records up to date.

class AirtableUpsertRecordAction < Sublayer::Actions::Base
  def initialize(base_id:, table_name:, fields:, unique_field:)
    @base_id = base_id
    @table_name = table_name
    @fields = fields
    @unique_field = unique_field
    @api_key = ENV['AIRTABLE_API_KEY']
    
    Airrecord.api_key = @api_key
  end

  def call
    begin
      table = create_table_class
      existing_record = find_existing_record(table)
      
      if existing_record
        update_record(existing_record)
      else
        create_record(table)
      end
    rescue Airrecord::Error => e
      error_message = "Airtable API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error upserting Airtable record: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def create_table_class
    Class.new(Airrecord::Table) do
      self.base_key = @base_id
      self.table_name = @table_name
    end
  end

  def find_existing_record(table)
    unique_value = @fields[@unique_field]
    return nil unless unique_value

    records = table.all(filter: "{#{@unique_field}} = '#{unique_value}'")
    records.first
  end

  def update_record(record)
    @fields.each do |field, value|
      record[field] = value
    end

    record.save
    Sublayer.configuration.logger.log(:info, "Updated Airtable record: #{record.id}")
    record.id
  end

  def create_record(table)
    record = table.create(@fields)
    Sublayer.configuration.logger.log(:info, "Created new Airtable record: #{record.id}")
    record.id
  end
end