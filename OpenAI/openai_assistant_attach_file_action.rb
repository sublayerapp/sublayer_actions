require 'openai'

# Description: Sublayer::Action responsible for attaching files to OpenAI assistants.
# This action enables easy updating of assistant knowledge bases by attaching new files
# for retrieval augmented generation.
#
# It is initialized with an assistant_id and file_path, and optionally a purpose for the file.
# It returns the ID of the attached file.
#
# Example usage: When you want to update an OpenAI assistant's knowledge base with new
# documentation, training materials, or code files.

class OpenAIAssistantAttachFileAction < Sublayer::Actions::Base
  def initialize(assistant_id:, file_path:, purpose: nil)
    @assistant_id = assistant_id
    @file_path = file_path
    @purpose = purpose
    @client = OpenAI::Client.new(access_token: ENV['OPENAI_API_KEY'])
  end

  def call
    begin
      # First, upload the file to OpenAI
      file = upload_file
      Sublayer.configuration.logger.log(:info, "File uploaded successfully with ID: #{file['id']}")

      # Then, attach it to the assistant
      attach_file_to_assistant(file['id'])
      Sublayer.configuration.logger.log(:info, "File attached successfully to assistant #{@assistant_id}")

      file['id']
    rescue StandardError => e
      error_message = "Error attaching file to assistant: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def upload_file
    raise StandardError, "File not found: #{@file_path}" unless File.exist?(@file_path)

    response = @client.files.create(
      parameters: {
        file: File.open(@file_path, 'rb'),
        purpose: 'assistants'
      }
    )

    unless response['id']
      raise StandardError, "Failed to upload file: #{response['error']}"
    end

    response
  end

  def attach_file_to_assistant(file_id)
    response = @client.assistants.files.create(
      assistant_id: @assistant_id,
      parameters: {
        file_id: file_id
      }
    )

    unless response['id']
      raise StandardError, "Failed to attach file to assistant: #{response['error']}"
    end

    response
  end
end
