require 'net/smtp'

# Description: Sublayer::Action responsible for sending notification emails through a specified SMTP server.
# This action is useful for alerting users about key events or updates.
#
# It is initialized with smtp_settings (hash containing server, port, domain, user_name, password),
# to (recipient email address), subject, and body. It returns true if the email is sent successfully.
#
# Example usage: For sending automated alerts and notifications to users based on AI insights or process updates.

class EmailSendNotificationAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, to:, subject:, body:)
    @smtp_settings = smtp_settings
    @to = to
    @subject = subject
    @body = body
  end

  def call
    send_email
  rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
    error_message = "Error sending email: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Unexpected error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def send_email
    message = <<~MESSAGE_END
      From: Notification System <#{@smtp_settings[:user_name]}>
      To: <#{@to}>
      Subject: #{@subject}

      #{@body}
    MESSAGE_END

    Net::SMTP.start(@smtp_settings[:server], @smtp_settings[:port], @smtp_settings[:domain],
                    @smtp_settings[:user_name], @smtp_settings[:password], :plain) do |smtp|
      smtp.send_message message, @smtp_settings[:user_name], @to
    end

    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    true
  end
end