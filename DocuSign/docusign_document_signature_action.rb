require 'docusign_esign'

# Description: Sublayer::Action responsible for sending documents for electronic signatures via DocuSign.
# This action is crucial for automating legal and business document authorization processes.
#
# It is initialized with an account_id, envelope_definition, and optionally a base_path.
# It returns the envelope_id, which can be used to track the envelope status.
#
# Example usage: When you need to send a contract for signatures to multiple recipients in a workflow automation.

class DocusignDocumentSignatureAction < Sublayer::Actions::Base
  def initialize(account_id:, envelope_definition:, base_path: nil)
    @account_id = account_id
    @envelope_definition = envelope_definition
    @base_path = base_path || 'https://demo.docusign.net/restapi'
    configure_client
  end

  def call
    send_envelope
  rescue DocuSign_eSign::ApiError => e
    error_message = "DocuSign API error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error sending DocuSign document for signature: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def configure_client
    configuration = DocuSign_eSign::Configuration.new
    configuration.host = @base_path
    configuration.access_token = ENV['DOCUSIGN_ACCESS_TOKEN']

    @api_client = DocuSign_eSign::ApiClient.new(configuration)
  end

  def send_envelope
    envelopes_api = DocuSign_eSign::EnvelopesApi.new(@api_client)
    results = envelopes_api.create_envelope(@account_id, { envelope_definition: @envelope_definition })
    envelope_id = results.envelope_id
    Sublayer.configuration.logger.log(:info, "Envelope sent successfully with ID: #{envelope_id}")
    envelope_id
  end
end
