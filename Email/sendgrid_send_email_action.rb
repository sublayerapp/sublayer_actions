require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending emails using the SendGrid API.
# This action is intended to be used for sending notifications, reports, or other automated communications from Sublayer agents.
#
# It is initialized with the following parameters:
# - to: The recipient's email address
# - from: The sender's email address
# - subject: The email subject
# - body: The email body
# It returns the SendGrid API response object to confirm the email was sent successfully.
#
# Example usage: When you want to send a notification or update from an AI process to a user via email.

class SendgridSendEmailAction < Sublayer::Actions::Base
  def initialize(to:, from:, subject:, body:)
    @to = to
    @from = from
    @subject = subject
    @body = body
    @sendgrid_client = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
  end

  def call
    mail = SendGrid::Mail.new
    mail.from = SendGrid::Email.new(email: @from)
    mail.subject = @subject
    personalization = SendGrid::Personalization.new
    personalization.add_to(SendGrid::Email.new(email: @to))
    mail.add_personalization(personalization)
    mail.add_content(SendGrid::Content.new(type: 'text/plain', value: @body))

    begin
      response = @sendgrid_client.client.mail._('send').post(request_body: mail.to_json)
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      response
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end