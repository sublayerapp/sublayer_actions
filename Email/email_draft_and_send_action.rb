require 'mail'

# Description: Sublayer::Action to compose and send emails using SMTP for Gmail or Outlook.
# This action facilitates automated communication tasks by generating emails from templates or AI-generated content.
#
# It is initialized with the SMTP details, recipient email, subject, body, and optional attachments.
# It returns a confirmation message upon successful sending.
#
# Example usage: When you need to send a series of AI-generated reports to different stakeholders via email.

class EmailDraftAndSendAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, recipient_email:, subject:, body:, attachments: [])
    @smtp_settings = smtp_settings
    @recipient_email = recipient_email
    @subject = subject
    @body = body
    @attachments = attachments
  end

  def call
    begin
      Mail.defaults do
        delivery_method :smtp, @smtp_settings
      end

      mail = Mail.new do
        from @smtp_settings[:user_name]
        to @recipient_email
        subject @subject
        body @body
      end

      @attachments.each do |attachment|
        mail.add_file(attachment)
      end

      mail.deliver!
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      "Email sent successfully to #{@recipient_email}"
    rescue StandardError => e
      error_message = "Error sending email to #{@recipient_email}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
