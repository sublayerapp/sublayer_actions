require 'sublayer'
require 'pg'

module Sublayer
  module Actions
    class DatabaseQueryExecutorAction < Sublayer::Actions::Base
      def initialize(config)
        super
        @connection_params = config['connection_params']
        @query = config['query']
      end

      def call
        begin
          connection = PG.connect(@connection_params)
          logger.info("Connected to database successfully")
          
          result = connection.exec(@query)
          logger.info("Query executed successfully")
          
          # Process the result
          processed_result = process_result(result)
          
          # Return the processed result
          return processed_result
        rescue PG::Error => e
          logger.error("Database error occurred: #{e.message}")
          raise Sublayer::Actions::ActionError.new("Database query execution failed: #{e.message}")
        ensure
          connection&.close
          logger.info("Database connection closed")
        end
      end

      private

      def process_result(result)
        # Convert the result to a hash for easier handling
        result.map { |row| row.transform_keys(&:to_sym) }
      end

      def validate_config
        raise Sublayer::Actions::ConfigurationError.new("Missing connection parameters") unless @connection_params
        raise Sublayer::Actions::ConfigurationError.new("Missing query") unless @query
      end
    end
  end
end
