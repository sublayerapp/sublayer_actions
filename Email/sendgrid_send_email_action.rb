require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending emails using the SendGrid API.
# This action allows for easy integration of email communication into Sublayer workflows,
# enabling LLMs to send notifications, reports, and other generated content.
#
# It is initialized with the necessary parameters for sending an email: to, from, subject, and content.
# It returns the SendGrid API response to confirm successful email sending.
#
# Example usage: When you want to send an email notification based on LLM-generated content or trigger an email as part of an AI-driven workflow.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(to:, from:, subject:, content:)
    @to = to
    @from = from
    @subject = subject
    @content = content
    @client = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY']).client
  end

  def call
    begin
      mail = SendGrid::Mail.new
      mail.from = SendGrid::Email.new(email: @from)
      personalization = SendGrid::Personalization.new
      personalization.add_to(SendGrid::Email.new(email: @to))
      mail.add_personalization(personalization)
      mail.subject = @subject
      mail.add_content(SendGrid::Content.new(type: 'text/plain', value: @content))

      response = @client.mail._('send').post(request_body: mail.to_json)

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      response
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end