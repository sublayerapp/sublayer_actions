require 'googleauth'
require 'google_drive'

# Description: Sublayer::Action responsible for reading data from a Google Sheet.
# It takes a sheet ID, range, and an optional filter query to return specific rows.
# Returns the sheet data in a specified output format (defaulting to CSV).

class GoogleSheetsReadDataAction < Sublayer::Actions::Base
  OUTPUT_FORMATS = %i[csv json].freeze

  def initialize(spreadsheet_id:, range:, filter: nil, output_format: :csv)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @filter = filter
    @output_format = output_format

    unless OUTPUT_FORMATS.include?(@output_format)
      raise ArgumentError, "Invalid output_format: #{@output_format}. Must be one of #{OUTPUT_FORMATS.join(', ')}"
    end

    @session = GoogleDrive::Session.from_service_account_key(StringIO.new(ENV['GOOGLE_SERVICE_ACCOUNT_KEY']))
  end

  def call
    begin
      worksheet = @session.spreadsheet_by_key(@spreadsheet_id).worksheet_by_title(@range.split('!')[0])
      range_data = worksheet.range(@range.split('!')[1])

      filtered_data = if @filter
                        filter_data(range_data)
                      else
                        range_data.rows
                      end

      format_data(filtered_data)
    rescue Google::Apis::ClientError => e
      Sublayer.configuration.logger.log(:error, "Error reading from Google Sheet: #{e.message}")
      raise e
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error processing sheet data: #{e.message}")
      raise e
    end
  end

  private

  def filter_data(range_data)
      range_data.rows.select do |row|
          @filter.all? do |key, value|
              row_index = range_data.first.index(key.to_s)

              row_index && row[row_index] == value
          end
      end
  end

  def format_data(data)
    case @output_format
    when :csv
      CSV.generate do |csv|
        data.each { |row| csv << row }
      end
    when :json
      headers = data[0]
      JSON.generate(data[1..].map { |row| headers.zip(row).to_h })
    end
  end
end