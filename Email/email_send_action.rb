require 'net/smtp'

# Description: Sublayer::Action responsible for sending emails using SMTP.
# This action allows for easy integration of email sending capabilities within a Sublayer workflow,
# enabling automated notifications, reports, or custom AI-generated messages to be sent via email.
#
# It is initialized with recipient email, subject, body, and optional sender email and SMTP settings.
# On successful execution, it sends the email and returns true.
#
# Example usage: When you want to send AI-generated reports or notifications via email.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: nil, smtp_settings: {})
    @to = to
    @subject = subject
    @body = body
    @from = from || ENV['DEFAULT_FROM_EMAIL']
    @smtp_settings = {
      address: ENV['SMTP_ADDRESS'],
      port: ENV['SMTP_PORT'],
      domain: ENV['SMTP_DOMAIN'],
      user_name: ENV['SMTP_USERNAME'],
      password: ENV['SMTP_PASSWORD'],
      authentication: :login,
      enable_starttls_auto: true
    }.merge(smtp_settings)
  end

  def call
    begin
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to \#{@to}")
      true
    rescue Net::SMTPAuthenticationError, Net::SMTPServerBusy, Net::SMTPSyntaxError, Net::SMTPFatalError, Net::SMTPUnknownError => e
      error_message = "Error sending email: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    message = <<MESSAGE_END
From: #{@from}
To: #{@to}
Subject: #{@subject}

#{@body}
MESSAGE_END

    Net::SMTP.start(@smtp_settings[:address],
                    @smtp_settings[:port],
                    @smtp_settings[:domain],
                    @smtp_settings[:user_name],
                    @smtp_settings[:password],
                    @smtp_settings[:authentication]) do |smtp|
      smtp.send_message message, @from, @to
    end
  end
end