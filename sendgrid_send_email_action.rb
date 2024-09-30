require 'sendgrid-ruby'
include SendGrid

module Sublayer
  module Actions
    class SendgridSendEmailAction < Sublayer::Actions::Base
      def initialize(config)
        super
        @api_key = config[:api_key] || ENV['SENDGRID_API_KEY']
        @from_email = config[:from_email]
        @to_email = config[:to_email]
        @subject = config[:subject]
        @content = config[:content]
      end

      def call
        validate_params
        send_email
      rescue => e
        log_error("Error sending email: #{e.message}")
        raise e
      end

      private

      def validate_params
        raise ArgumentError, 'Missing Sendgrid API key' if @api_key.nil? || @api_key.empty?
        raise ArgumentError, 'Missing from email' if @from_email.nil? || @from_email.empty?
        raise ArgumentError, 'Missing to email' if @to_email.nil? || @to_email.empty?
        raise ArgumentError, 'Missing subject' if @subject.nil? || @subject.empty?
        raise ArgumentError, 'Missing content' if @content.nil? || @content.empty?
      end

      def send_email
        from = Email.new(email: @from_email)
        to = Email.new(email: @to_email)
        content = Content.new(type: 'text/plain', value: @content)
        mail = Mail.new(from, @subject, to, content)

        sg = SendGrid::API.new(api_key: @api_key)
        response = sg.client.mail._('send').post(request_body: mail.to_json)

        log_info("Email sent successfully. Status code: #{response.status_code}")
        response
      end
    end
  end
end