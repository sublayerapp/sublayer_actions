require 'mail'

# Description: Sublayer::Action responsible for sending email notifications.
# This action enables sending emails through SMTP, offering seamless integration with services like SendGrid or Amazon SES.
#
# It is initialized with recipient email(s), subject, body, and optional parameters for attachments or SMTP settings.
# It returns a confirmation message on successful email delivery.
#
# Example usage: When you want to send notifications from an AI process directly to stakeholders via email.

class EmailNotificationAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, smtp_settings: {}, attachments: [])
    @to = to
    @subject = subject
    @body = body
    @smtp_settings = smtp_settings
    @attachments = attachments
  end

  def call
    setup_mail_defaults

    mail = Mail.new do
      from    @smtp_settings[:from]
      to      @to
      subject @subject
      body    @body
    end

    @attachments.each do |attachment|
      mail.add_file(attachment)
    end

    begin
      mail.delivery_method :smtp, @smtp_settings
      mail.deliver!
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      "Email sent successfully"
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_mail_defaults
    Mail.defaults do
      retriever_method :pop3, address:    "pop.gmail.com",
                              port:       995,
                              user_name:  ENV['EMAIL_USER_NAME'],
                              password:   ENV['EMAIL_PASSWORD'],
                              enable_ssl: true
    end
  end
end
