# Description: Sublayer::Action responsible for sending emails using the SendGrid API.
# This action allows for sending emails from within a Sublayer workflow, enabling notifications,
# updates, or other email-based communication.
#
# Requires: `sendgrid-ruby` gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with sender, recipient, subject, body, and optional attachments.
# It returns the SendGrid API response.
#
# Example usage: When you want to send an email notification from an AI process.

class SendGridSendEmailAction < Sublayer::Actions::Base
  def initialize(sender:, recipient:, subject:, body:, attachments: [])
    @sender = sender
    @recipient = recipient
    @subject = subject
    @body = body
    @attachments = attachments
    @client = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
  end

  def call
    begin
      mail = SendGrid::Mail.new
      mail.from = SendGrid::Email.new(email: @sender)
      mail.subject = @subject
      mail.add_personalization(SendGrid::Personalization.new.add_to(SendGrid::Email.new(email: @recipient)))
      mail.add_content(SendGrid::Content.new(type: 'text/plain', value: @body))

      @attachments.each do |attachment|
        mail.add_attachment(SendGrid::Attachment.new(
          file_content: Base64.strict_encode64(File.read(attachment[:path])),
          file_type: attachment[:type],
          file_name: attachment[:name],
          disposition: 'attachment'
        ))
      end

      response = @client.client.mail._('send').post(request_body: mail.to_json)

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@recipient}")
      response
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end