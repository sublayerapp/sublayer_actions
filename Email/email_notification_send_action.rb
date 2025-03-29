require 'net/smtp'

# Description: Sublayer::Action responsible for sending an email notification through a specified SMTP server.
# This action is useful for sending alerts or updates via email, especially in automated workflows or monitoring systems.
#
# It is initialized with smtp_settings (containing server, port, domain, username, password, and authentication type),
# from, to, subject, and body.
# It returns a boolean indicating the success of the email sending operation.
#
# Example usage: When you need to notify a team about an important update or alert via email.

class EmailNotificationSendAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, from:, to:, subject:, body:)
    @smtp_settings = smtp_settings
    @from = from
    @to = to
    @subject = subject
    @body = body
  end

  def call
    send_email
  rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
    error_message = "SMTP error during email sending: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error sending email: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def send_email
    message = <<~MESSAGE_END
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    MESSAGE_END

    Net::SMTP.start(@smtp_settings[:address], @smtp_settings[:port], @smtp_settings[:domain],
                    @smtp_settings[:user_name], @smtp_settings[:password], :plain) do |smtp|
      smtp.send_message message, @from, @to
    end
    
    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    true
  end
end
