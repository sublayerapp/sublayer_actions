class EmailSendAction < Sublayer::Actions::Base
  def initialize(to:, from:, subject:, body:, attachments: [], api_key: nil, api_provider: 'sendgrid')
    @to = to
    @from = from
    @subject = subject
    @body = body
    @attachments = attachments
    @api_key = api_key || ENV['SENDGRID_API_KEY']
    @api_provider = api_provider

    raise "API key for #{api_provider} is required" unless @api_key
  end

  def call
    begin
      if @api_provider == 'sendgrid'
        send_with_sendgrid
      elsif @api_provider == 'mailgun'
        send_with_mailgun
      else
        raise "Unsupported email provider: #{@api_provider}"
      end

      Sublayer.configuration.logger.log(:info, "Email sent successfully to #{@to}")
      true
    rescue StandardError => e
      Sublayer.configuration.logger.log(:error, "Error sending email: #{e.message}")
      raise e
    end
  end

  private

  def send_with_sendgrid
    # Implement SendGrid email sending logic here
    # using 'sendgrid-ruby' gem or similar
  end

  def send_with_mailgun
    # Implement Mailgun email sending logic here
    # using 'mailgun-ruby' gem or similar
  end
end