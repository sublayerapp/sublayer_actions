class DatabaseInteractionAction < Sublayer::Actions::Base
  # Description: Sublayer::Action for interacting with databases.
  #
  # It can be initialized with the following parameters:
  # - db_type: The type of database (e.g., 'postgresql', 'mysql', 'sqlite3')
  # - db_config: A hash containing connection parameters (e.g., host, database, username, password)
  # - query: The SQL query to execute
  #
  # Example usage:
  #   action = DatabaseInteractionAction.new(
  #     db_type: 'postgresql',
  #     db_config: {
  #       host: 'localhost',
  #       database: 'my_database',
  #       username: 'my_user',
  #       password: 'my_password'
  #     },
  #     query: 'SELECT * FROM users'
  #   )
  #   result = action.call

  attr_reader :db_type, :db_config, :query

  def initialize(db_type:, db_config:, query:)
    @db_type = db_type
    @db_config = db_config
    @query = query
  end

  def call
    begin
      require 'active_record'

      # Establish a connection to the database
      ActiveRecord::Base.establish_connection(db_config.merge(adapter: db_type))

      # Execute the query and return the result
      ActiveRecord::Base.connection.execute(query)
    rescue StandardError => e
      logger.error "Error interacting with database: #{e.message}"
      raise e
    ensure
      # Close the database connection
      ActiveRecord::Base.connection.close if ActiveRecord::Base.connected?
    end
  end
end