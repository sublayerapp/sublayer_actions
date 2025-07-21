require 'net/smtp'

# Description: Sublayer::Action responsible for sending an email notification via SMTP.
# It can be used to alert users or stakeholders about AI-generated insights or process completions.
#
# This action is initialized with smtp_settings, from, to, subject, and body.
# It returns a confirmation message upon successful sending of the email.
#
# Example usage: To notify a user about the completion of an AI process or to share AI-generated insights.

class EmailNotificationAction < Sublayer::Actions::Base
  def initialize(smtp_settings:, from:, to:, subject:, body:)
    @smtp_settings = smtp_settings
    @from = from
    @to = to
    @subject = subject
    @body = body
  end

  def call
    send_email
  rescue Net::SMTPFatalError => e
    error_message = "SMTP error: #{e.message}"
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
                    @smtp_settings[:user_name], @smtp_settings[:password], @smtp_settings[:authentication]) do |smtp|
      smtp.send_message message, @from, @to
    end
    Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
  end
end