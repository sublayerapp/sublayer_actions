module Sublayer
  module Actions
    class EmailNotificationAction < Base
      require 'net/smtp'
      require 'logger'

      def initialize(smtp_settings, recipients, subject, message)
        @smtp_settings = smtp_settings
        @recipients = recipients
        @subject = subject
        @message = message
        @logger = Logger.new(STDOUT)
      end

      def call
        begin
          smtp = Net::SMTP.new(@smtp_settings[:address], @smtp_settings[:port])
          smtp.enable_starttls_auto if @smtp_settings[:enable_starttls_auto]

          smtp.start(@smtp_settings[:domain], @smtp_settings[:user_name], @smtp_settings[:password], @smtp_settings[:authentication]) do |smtp_client|
            mail_text = <<~MAIL
              From: #{@smtp_settings[:from]}
              To: #{@recipients.join(",")}
              Subject: #{@subject}

              #{@message}
            MAIL

            smtp_client.send_message mail_text, @smtp_settings[:from], @recipients
          end
          @logger.info("Email successfully sent to #{@recipients.join(', ')}")
        rescue Net::SMTPFatalError, Net::SMTPSyntaxError => e
          @logger.error("Failed to send email due to SMTP error: #{e.message}")
        rescue Exception => e
          @logger.error("An error occurred: #{e.message}")
        end
      end
    end
  end
end