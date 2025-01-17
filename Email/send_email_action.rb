# Description: Sublayer::Action responsible for sending emails using a specified email provider API (e.g., SendGrid, Mailgun).
# It is initialized with recipient, subject and body and is expected to authenticate using environment variables.
# It returns the response code to confirm the message was sent successfully or raise an exception upon failure.
#
# Example usage: Sending an email containing content from a Sublayer::Generator

class SendEmailAction < Sublayer::Actions::Base
  def initialize(recipient:, subject:, body:, provider: "sendgrid")
    @recipient = recipient
    @subject = subject
    @body = body
    @provider = provider

    raise StandardError, "Unsupported email provider: \#{@provider}" unless %w[sendgrid mailgun].include?(@provider)

    @sendgrid_client = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY']) if @provider == "sendgrid"
    @mailgun_client = Mailgun::Client.new(ENV['MAILGUN_API_KEY']) if @provider == "mailgun"
  end

  def call
    begin
      response = send_email
      Sublayer.configuration.logger.log(:info, "Email sent successfully to \#{@recipient} using \#{@provider}")
      response
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: \#{e.message}")
      raise e
    end
  end

  private

  def send_email
    case @provider
    when "sendgrid"
      mail = SendGrid::Mail.new
      mail.from = SendGrid::Email.new(email: ENV.fetch('SENDGRID_FROM_EMAIL', 'no-reply@example.com'))
      mail.subject = @subject
      personalization = SendGrid::Personalization.new
      personalization.add_to(SendGrid::Email.new(email: @recipient))
      mail.add_personalization(personalization)
      mail.add_content(SendGrid::Content.new(type: 'text/plain', value: @body))
      @sendgrid_client.send(mail)
    when "mailgun"
      message_params = {
        :from => ENV.fetch('MAILGUN_FROM_EMAIL', 'no-reply@example.com'),
        :to => @recipient,
        :subject => @subject,
        :text => @body
      }
      @mailgun_client.send_message(ENV['MAILGUN_DOMAIN'], message_params)
    end
  end
end