class EmailSendAction < Sublayer::Actions::Base
  require 'sendgrid-ruby'
  include SendGrid

  def initialize(from:, to:, subject:, body:)
    @from = from
    @to = to
    @subject = subject
    @body = body
  end

  def call
    mail = SendGrid::Mail.new
    mail.from = SendGrid::Email.new(email: @from)
    mail.subject = @subject
    mail.add_personalization(SendGrid::Personalization.new(to: [SendGrid::Email.new(email: @to)]))
    mail.add_content(SendGrid::Content.new(type: 'text/plain', value: @body))

    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    begin
      response = sg.client.mail._('send').post(request_body: mail.to_json)
      Sublayer.configuration.logger.log(:info, "Email sent successfully -  Status code: #{response.status_code}")
    rescue Exception => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end
end