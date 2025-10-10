require 'chromadb'

# Description: Sublayer::Action responsible for upserting documents and their embeddings into ChromaDB.
# This action allows for easy integration with ChromaDB, a vector database commonly used in AI applications
# for storing and retrieving context-aware information.
#
# Requires: 'chromadb' gem
# $ gem install chromadb
# Or add `gem 'chromadb'` to your Gemfile
#
# It is initialized with a collection_name and an array of documents with their associated metadata and embeddings.
# Returns the IDs of the upserted documents.
#
# Example usage: When you want to maintain a knowledge base or store context for AI applications,
# allowing for semantic search and retrieval of relevant information later.

class ChromaDBUpsertAction < Sublayer::Actions::Base
  def initialize(collection_name:, documents:, embeddings:, ids: nil, metadatas: nil, host: 'localhost', port: 8000)
    @collection_name = collection_name
    @documents = documents
    @embeddings = embeddings
    @ids = ids || generate_ids(documents.length)
    @metadatas = metadatas
    @host = host
    @port = port
  end

  def call
    begin
      client = ChromaDB::Client.new(host: @host, port: @port)
      
      # Get or create collection
      collection = get_or_create_collection(client)
      
      # Prepare upsert parameters
      upsert_params = {
        documents: @documents,
        embeddings: @embeddings,
        ids: @ids
      }
      
      # Add metadatas if provided
      upsert_params[:metadatas] = @metadatas if @metadatas

      # Perform upsert operation
      collection.upsert(**upsert_params)

      Sublayer.configuration.logger.log(:info, "Successfully upserted #{@documents.length} documents to ChromaDB collection '#{@collection_name}'.")
      
      @ids
    rescue ChromaDB::Error => e
      error_message = "ChromaDB error during upsert: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error upserting to ChromaDB: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def get_or_create_collection(client)
    begin
      client.get_collection(name: @collection_name)
    rescue ChromaDB::Error
      client.create_collection(name: @collection_name)
    end
  end

  def generate_ids(count)
    Array.new(count) { SecureRandom.uuid }
  end
end