require 'google/apis/gmail_v1'
require 'google/api_client/client_secrets'
require 'mail'

# Description: Sublayer::Action responsible for creating draft emails in Gmail.
# This action enables AI workflows to prepare emails that can be reviewed by humans before sending.
#
# Requires: The following gems
# gem 'google-api-client'
# gem 'mail'
#
# It is initialized with recipients, subject, and body content.
# Returns the draft ID of the created email draft.
#
# Example usage: When an LLM generates email content that needs human review
# before being sent, this action can be used to create the draft in Gmail.

class GmailDraftCreateAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, cc: nil, bcc: nil)
    @to = Array(to).join(',')
    @cc = Array(cc).join(',') if cc
    @bcc = Array(bcc).join(',') if bcc
    @subject = subject
    @body = body
    @service = initialize_gmail_service
  end

  def call
    begin
      draft = create_draft
      Sublayer.configuration.logger.log(:info, "Gmail draft created successfully with ID: #{draft.id}")
      draft.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Gmail draft: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_gmail_service
    service = Google::Apis::GmailV1::GmailService.new
    service.authorization = Google::Auth::ServiceAccountCredentials.from_env(
      scope: ['https://www.googleapis.com/auth/gmail.compose']
    )
    service
  end

  def create_draft
    message = Mail.new
    message.to = @to
    message.cc = @cc if @cc
    message.bcc = @bcc if @bcc
    message.subject = @subject
    message.body = @body

    draft_message = Google::Apis::GmailV1::Message.new(
      raw: message.to_s.gsub(/\n/, '\r\n')
    )

    draft = Google::Apis::GmailV1::Draft.new(message: draft_message)
    @service.create_user_draft('me', draft)
  end
end
