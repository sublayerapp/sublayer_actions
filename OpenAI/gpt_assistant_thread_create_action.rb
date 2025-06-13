require 'openai'

# Description: Sublayer::Action responsible for creating a new thread in OpenAI's Assistant API.
# This action enables stateful conversations and memory in AI workflows by creating threads
# that can be used for ongoing interactions with an OpenAI Assistant.
#
# It is initialized with an assistant_id and optional initial messages.
# It returns the thread_id that can be used for future interactions.
#
# Example usage: When you want to start a new conversation thread with an OpenAI Assistant
# that maintains context and can be referenced in subsequent interactions.

class GptAssistantThreadCreateAction < Sublayer::Actions::Base
  def initialize(assistant_id:, initial_messages: [])
    @assistant_id = assistant_id
    @initial_messages = initial_messages
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      # Create a new thread
      thread = create_thread

      # Add initial messages if provided
      add_initial_messages(thread.id) unless @initial_messages.empty?

      Sublayer.configuration.logger.log(:info, "Created new Assistant thread: #{thread.id}")
      thread.id
    rescue OpenAI::Error => e
      error_message = "Error creating Assistant thread: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error creating Assistant thread: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def create_thread
    @client.threads.create
  end

  def add_initial_messages(thread_id)
    @initial_messages.each do |message|
      @client.messages.create(
        thread_id: thread_id,
        role: message[:role] || 'user',
        content: message[:content]
      )
    end
  end
end