require 'mail'

# Description: Sublayer::Action for sending emails with attachments.
# It uses the 'mail' gem to send emails via SMTP.
#
# Example usage: Sending email notifications or reports based on LLM-generated content.
class SendEmailAction < Sublayer::Actions::Base
  def initialize(to:, from:, subject:, body:, attachments: [], smtp_settings: {})
    @to = to
    @from = from
    @subject = subject
    @body = body
    @attachments = attachments
    @smtp_settings = smtp_settings.reverse_merge(address: 'smtp.gmail.com', port: 587, user_name: ENV['SMTP_USERNAME'], password: ENV['SMTP_PASSWORD'], authentication: :plain, enable_starttls_auto: true)
  end

  def call
    begin
      mail = Mail.new do
        from @from
        to @to
        subject @subject
        text_part do
          body @body
        end

        @attachments.each do |attachment|
          add_file attachment
        end
      end

      mail.delivery_method :smtp, @smtp_settings

      mail.deliver
      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end