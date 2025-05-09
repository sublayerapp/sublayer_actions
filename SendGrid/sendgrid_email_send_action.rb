require 'sendgrid-ruby'

# Description: Sublayer::Action responsible for sending an email using the SendGrid API.
# This action allows for easy integration of email sending capabilities into Sublayer workflows,
# enabling notifications, reports, or AI-generated content to be sent via email.
#
# Requires: 'sendgrid-ruby' gem
# $ gem install sendgrid-ruby
# Or add `gem 'sendgrid-ruby'` to your Gemfile
#
# It is initialized with to, subject, and body parameters, with optional from, cc, and bcc.
# It returns the SendGrid API response to confirm the email was sent successfully.
#
# Example usage: When you want to send an email with AI-generated content or notifications from your Sublayer workflow.

class SendGridEmailSendAction < Sublayer::Actions::Base
  include SendGrid

  def initialize(to:, subject:, body:, from: ENV['SENDGRID_FROM_EMAIL'], cc: nil, bcc: nil)
    @to = to
    @subject = subject
    @body = body
    @from = from
    @cc = cc
    @bcc = bcc
    @api_key = ENV['SENDGRID_API_KEY']
  end

  def call
    begin
      response = send_email
      log_success(response)
      response
    rescue StandardError => e
      log_error(e)
      raise e
    end
  end

  private

  def send_email
    mail = build_mail
    sg = SendGrid::API.new(api_key: @api_key)
    sg.client.mail._('send').post(request_body: mail.to_json)
  end

  def build_mail
    mail = Mail.new
    mail.from = Email.new(email: @from)
    mail.subject = @subject
    mail.add_content(Content.new(type: 'text/plain', value: @body))
    
    add_recipients(mail)

    mail
  end

  def add_recipients(mail)
    mail.add_personalization(build_personalization)
  end

  def build_personalization
    personalization = Personalization.new
    add_to_recipients(personalization)
    add_cc_recipients(personalization) if @cc
    add_bcc_recipients(personalization) if @bcc
    personalization
  end

  def add_to_recipients(personalization)
    [@to].flatten.each do |recipient|
      personalization.add_to(Email.new(email: recipient))
    end
  end

  def add_cc_recipients(personalization)
    [@cc].flatten.each do |recipient|
      personalization.add_cc(Email.new(email: recipient))
    end
  end

  def add_bcc_recipients(personalization)
    [@bcc].flatten.each do |recipient|
      personalization.add_bcc(Email.new(email: recipient))
    end
  end

  def log_success(response)
    Sublayer.configuration.logger.log(:info, "Email sent successfully. Status code: #{response.status_code}")
  end

  def log_error(error)
    Sublayer.configuration.logger.log(:error, "Error sending email: #{error.message}")
  end
end
