require 'mail'

# Description: Sublayer::Action responsible for sending emails.
# Useful for notifications or other communications in AI workflows.

# Example usage:
# When you want to send an email notification from an AI process.
class SendEmailAction < Sublayer::Actions::Base
  def initialize(from:, to:, subject:, body:, delivery_method: :smtp, options: {})
    @from = from
    @to = to
    @subject = subject
    @body = body
    @delivery_method = delivery_method
    @options = options
  end

  def call
    begin
      mail = Mail.new do
        from @from
        to @to
        subject @subject
        body @body
      end

      mail.delivery_method @delivery_method, @options
      mail.deliver

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end