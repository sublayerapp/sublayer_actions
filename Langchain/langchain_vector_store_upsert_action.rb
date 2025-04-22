require 'langchain'

# Description: Sublayer::Action responsible for upserting documents into a Langchain vector store.
# This action handles the process of embedding documents and storing them in vector databases
# like Pinecone or Chroma for use in AI applications.
#
# Requires: 'langchain' gem and appropriate vector store backend gems
# $ gem install langchain
# Plus either:
# $ gem install pinecone # for Pinecone backend
# or
# $ gem install chroma-db # for Chroma backend
#
# It is initialized with the text content, optional metadata, and vector store configuration.
# It returns a success message with the IDs of the upserted documents.
#
# Example usage: When you want to maintain a dynamic knowledge base for AI applications
# by adding or updating documents in a vector store.

class LangchainVectorStoreUpsertAction < Sublayer::Actions::Base
  def initialize(
    content:,
    metadata: {},
    vector_store_type: :chroma,
    collection_name: 'default',
    embedding_model: 'text-embedding-ada-002'
  )
    @content = content
    @metadata = metadata
    @vector_store_type = vector_store_type
    @collection_name = collection_name
    @embedding_model = embedding_model
    
    setup_vector_store
    setup_embeddings
  end

  def call
    begin
      # Convert content to document format
      documents = prepare_documents
      
      # Embed and upsert documents
      response = @vector_store.add_documents(documents)
      
      success_message = "Successfully upserted #{documents.length} documents to #{@vector_store_type}"
      Sublayer.configuration.logger.log(:info, success_message)
      
      response
    rescue StandardError => e
      error_message = "Error upserting to vector store: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_vector_store
    @vector_store = case @vector_store_type
    when :pinecone
      validate_pinecone_env_vars
      Langchain::Vectorsearch::Pinecone.new(
        api_key: ENV['PINECONE_API_KEY'],
        environment: ENV['PINECONE_ENVIRONMENT'],
        index_name: @collection_name
      )
    when :chroma
      Langchain::Vectorsearch::Chroma.new(
        url: ENV['CHROMA_API_URL'],
        collection_name: @collection_name
      )
    else
      raise ArgumentError, "Unsupported vector store type: #{@vector_store_type}"
    end
  end

  def setup_embeddings
    @embeddings = Langchain::Embeddings::OpenAI.new(
      api_key: ENV['OPENAI_API_KEY'],
      model_name: @embedding_model
    )
  end

  def prepare_documents
    # Handle both single strings and arrays of strings
    contents = @content.is_a?(Array) ? @content : [@content]
    
    contents.map do |text|
      Langchain::Document.new(
        text: text,
        metadata: @metadata
      )
    end
  end

  def validate_pinecone_env_vars
    required_vars = ['PINECONE_API_KEY', 'PINECONE_ENVIRONMENT']
    missing_vars = required_vars.select { |var| ENV[var].nil? || ENV[var].empty? }
    
    unless missing_vars.empty?
      raise StandardError, "Missing required environment variables: #{missing_vars.join(', ')}"
    end
  end
end