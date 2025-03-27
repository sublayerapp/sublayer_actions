# Description: Sublayer::Action responsible for managing chat histories for an OpenAI-powered chat.
# This action is designed to store and retrieve conversation histories, organizing them for quick access and reference.
#
# It is initialized with a storage_path where the chat histories will be saved.
# The call method can either save a new chat history or retrieve existing ones.
#
# Example usage: When you want to store conversation histories for analysis or to resume a conversation with context.

class OpenAIChatHistoryManagerAction < Sublayer::Actions::Base
  def initialize(storage_path:)
    @storage_path = storage_path
    Dir.mkdir(@storage_path) unless Dir.exist?(@storage_path)
  end

  def call(action:, conversation_id:, message: nil)
    case action
    when :store
      store_message(conversation_id, message)
    when :retrieve
      retrieve_history(conversation_id)
    else
      raise ArgumentError, "Invalid action: #{action}. Expected :store or :retrieve."
    end
  rescue StandardError => e
    error_message = "Error managing chat history: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def store_message(conversation_id, message)
    file_path = File.join(@storage_path, "#{conversation_id}.txt")
    File.open(file_path, 'a') do |file|
      file.puts(message)
    end
    Sublayer.configuration.logger.log(:info, "Message stored successfully for conversation ID: #{conversation_id}")
  end

  def retrieve_history(conversation_id)
    file_path = File.join(@storage_path, "#{conversation_id}.txt")
    if File.exist?(file_path)
      File.read(file_path)
    else
      error_message = "No chat history found for conversation ID: #{conversation_id}"
      Sublayer.configuration.logger.log(:warn, error_message)
      nil
    end
  end
end
