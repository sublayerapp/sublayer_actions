require 'net/smtp'
require 'mail'

# Description: Sublayer::Action responsible for sending emails using SMTP.
# This action supports attachments and HTML content, making it useful for
# automated notifications or reports generated by AI processes.
#
# It is initialized with recipient email, subject, body, and optional parameters
# for CC, BCC, attachments, and HTML content.
# It returns a boolean indicating whether the email was sent successfully.
#
# Example usage: When you want to send an email notification or report
# generated by an AI process to a specified recipient.

class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, subject:, body:, from: ENV['EMAIL_FROM_ADDRESS'], cc: nil, bcc: nil, attachments: [], html_content: nil)
    @to = to
    @subject = subject
    @body = body
    @from = from
    @cc = cc
    @bcc = bcc
    @attachments = attachments
    @html_content = html_content
  end

  def call
    begin
      mail = Mail.new do
        from    @from
        to      @to
        subject @subject
        
        if @html_content
          html_part do
            content_type 'text/html; charset=UTF-8'
            body @html_content
          end
        else
          body @body
        end

        @attachments.each do |attachment|
          add_file attachment
        end

        cc @cc if @cc
        bcc @bcc if @bcc
      end

      mail.delivery_method :smtp, {
        address: ENV['SMTP_SERVER'],
        port: ENV['SMTP_PORT'],
        user_name: ENV['SMTP_USERNAME'],
        password: ENV['SMTP_PASSWORD'],
        authentication: :login,
        enable_starttls_auto: true
      }

      mail.deliver!
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      true
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
