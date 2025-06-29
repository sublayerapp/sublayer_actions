require 'airrecord'

# Description: Sublayer::Action responsible for upserting (updating or inserting) a record in an Airtable base.
# This action provides a simple interface to maintain data in Airtable, useful for AI agents needing
# a lightweight database solution.
#
# Requires: 'airrecord' gem
# $ gem install airrecord
# Or add `gem 'airrecord'` to your Gemfile
#
# It is initialized with base_id, table_name, record_identifier (field/value to match for updates),
# and fields to upsert.
#
# Example usage: When an AI agent needs to maintain state or update records in Airtable based on
# processed information or generated content.

class AirtableUpsertRecordAction < Sublayer::Actions::Base
  def initialize(base_id:, table_name:, record_identifier:, fields:)
    @base_id = base_id
    @table_name = table_name
    @record_identifier = record_identifier # Hash with field_name: value to identify existing record
    @fields = fields # Hash of field_name: value pairs to upsert
    @api_key = ENV['AIRTABLE_API_KEY']
    
    Airrecord.api_key = @api_key
  end

  def call
    begin
      table = setup_table
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

  def setup_table
    Class.new(Airrecord::Table) do
      self.base_key = @base_id
      self.table_name = @table_name
    end
  end

  def find_existing_record(table)
    field_name = @record_identifier.keys.first
    field_value = @record_identifier.values.first
    
    records = table.all(filter: "{#{field_name}} = '#{field_value}'")
    records.first
  end

  def update_record(record)
    @fields.each do |field, value|
      record[field] = value
    end
    
    record.save
    Sublayer.configuration.logger.log(:info, "Successfully updated Airtable record")
    record.id
  end

  def create_record(table)
    record = table.create(@fields)
    Sublayer.configuration.logger.log(:info, "Successfully created new Airtable record")
    record.id
  end
end