require 'net/smtp'

# Description: Sublayer::Action responsible for sending an email using a specified SMTP server.
# This action is useful for integrating traditional email notifications into Sublayer workflows.
#
# It is initialized with smtp_server, port, domain, from, to, subject, and body. Optional parameters
# include username and password for SMTP authentication.
# It returns true if the email is sent successfully.
#
# Example usage: When you want to notify users about workflow events via email.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(smtp_server:, port:, domain:, from:, to:, subject:, body:, username: nil, password: nil)
    @smtp_server = smtp_server
    @port = port
    @domain = domain
    @from = from
    @to = to
    @subject = subject
    @body = body
    @username = username
    @password = password
  end

  def call
    begin
      send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to ")
      true
    rescue StandardError => e
      error_message = "Error sending email: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def send_email
    message = <<~EOF
      From: \\#{@from}
      To: \\#{@to}
      Subject: \\#{@subject}

      \\#{@body}
    EOF

    smtp = Net::SMTP.new(@smtp_server, @port)
    smtp.enable_starttls_auto if @username && @password

    smtp.start(@domain, @username, @password, @username && @password ? :login : nil) do |smtp|
      smtp.send_message(message, @from, @to)
    end
  end
end