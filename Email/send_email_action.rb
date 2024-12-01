require 'mail'

# Description: Sublayer::Action responsible for sending emails using a specified email service.
# This action enables AI agents to send notifications, reports, or other email communications based on generated content or triggered events.
#
# It is initialized with sender, recipient, subject, and body parameters, as well as optional attachments, cc, and bcc.
# It returns true on successful email delivery, otherwise raises an error.
#
# Example usage: When you want to send an email notification based on the output of an LLM or a triggered event.

class SendEmailAction < Sublayer::Actions::Base
  def initialize(sender:, recipient:, subject:, body:, attachments: [], cc: [], bcc: [])
    @sender = sender
    @recipient = recipient
    @subject = subject
    @body = body
    @attachments = attachments
    @cc = cc
    @bcc = bcc
  end

  def call
    begin
      mail = Mail.new do
        from @sender
        to @recipient
        cc @cc unless @cc.empty?
        bcc @bcc unless @bcc.empty?
        subject @subject
        body @body

        @attachments.each do |attachment|
          add_file attachment
        end
      end

      mail.delivery_method :sendmail
      mail.deliver

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient}")
      true
    rescue StandardError => e
      error_message = "Error sending email: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end