require 'mail'

# Description: A Sublayer::Action responsible for sending emails through various providers like Gmail and Outlook.
# This versatile action is useful for sending notifications or reports on completed tasks.
#
# It is initialized with to, subject, body, and optional parameters for configuration.
#
# Example usage: When an AI-driven process completes a task, it can send a notification via email.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, smtp_config: {})
    @to = to
    @subject = subject
    @body = body
    @smtp_config = smtp_config
  end

  def call
    configure_mail_defaults
    send_email
  end

  private

  def configure_mail_defaults
    Mail.defaults do
      delivery_method :smtp, {
        address: @smtp_config.fetch(:address, 'smtp.gmail.com'),
        port: @smtp_config.fetch(:port, 587),
        user_name: @smtp_config[:user_name],
        password: @smtp_config[:password],
        authentication: @smtp_config.fetch(:authentication, 'plain'),
        enable_starttls_auto: @smtp_config.fetch(:enable_starttls_auto, true)
      }
    end
  end

  def send_email
    mail = Mail.new do
      from    @smtp_config[:user_name]
      to      @to
      subject @subject
      body    @body
    end

    begin
      mail.deliver!
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    rescue StandardError => e
      error_message = "Error sending email to #{@to}: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
