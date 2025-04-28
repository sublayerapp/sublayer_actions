require 'net/smtp'

# Description: Sublayer::Action responsible for sending an email using a specified SMTP server.
# This action is useful for sending notifications or updates as part of a Sublayer workflow.
#
# It is initialized with SMTP details (server, port, domain, username, and password), along with
the email content (to, from, subject, body).
# It returns a confirmation message upon successful sending of the email.
#
# Example usage: When you want to notify a user or a system about a specific event in your workflow.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(smtp_details:, to:, from:, subject:, body:)
    @smtp_details = smtp_details
    @to = to
    @from = from
    @subject = subject
    @body = body
  end

  def call
    message = <<~MESSAGE_END
      From: #{@from}
      To: #{@to}
      Subject: #{@subject}

      #{@body}
    MESSAGE_END

    begin
      Net::SMTP.start(@smtp_details[:server], @smtp_details[:port], @smtp_details[:domain],
                      @smtp_details[:username], @smtp_details[:password], :login) do |smtp|
        smtp.send_message message, @from, @to
      end
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      "Email sent successfully to #{@to}"
    rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
      error_message = "SMTP error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
