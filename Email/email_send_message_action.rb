# Description: Sublayer::Action responsible for sending a formatted email via a specified email service provider.
# It uses the `mail` gem to send emails.
#
# It is initialized with recipient_email, sender_email, subject, and body. Optionally allows CC and BCC.
# It returns true on successful delivery and raises an exception otherwise.
#
# Example usage: When you want to send an email notification from your workflow.

require 'mail'

class EmailSendMessageAction < Sublayer::Actions::Base
  def initialize(recipient_email:, sender_email:, subject:, body:, cc: nil, bcc: nil)
    @recipient_email = recipient_email
    @sender_email = sender_email
    @subject = subject
    @body = body
    @cc = cc
    @bcc = bcc

    Mail.defaults do
      delivery_method :smtp, {
        address:              ENV['SMTP_ADDRESS'],
        port:                 ENV['SMTP_PORT'].to_i,
        user_name:            ENV['SMTP_USERNAME'],
        password:             ENV['SMTP_PASSWORD'],
        authentication:       ENV['SMTP_AUTHENTICATION'],
        enable_starttls_auto: ENV['SMTP_ENABLE_STARTTLS_AUTO'] == "true",
        openssl_verify_mode:  ENV['SMTP_OPENSSL_VERIFY_MODE']
      }
    end
  end

  def call
    begin
      mail = Mail.new do
        to       @recipient_email
        from     @sender_email
        cc       @cc unless @cc.nil?
        bcc      @bcc unless @bcc.nil?
        subject  @subject
        body     @body
      end

      mail.deliver!
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient_email}")
      true
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end