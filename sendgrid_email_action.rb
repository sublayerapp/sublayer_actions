require 'sendgrid-ruby'
require 'sublayer'

module Sublayer
  module Actions
    class SendgridEmailAction < Sublayer::Actions::Base
      def initialize(config)
        @api_key = config[:api_key] || ENV['SENDGRID_API_KEY']
        @from_email = config[:from_email]
        @to_email = config[:to_email]
        @subject = config[:subject]
        @content = config[:content]
        
        raise ArgumentError, 'Sendgrid API key is required' if @api_key.nil?
        raise ArgumentError, 'From email is required' if @from_email.nil?
        raise ArgumentError, 'To email is required' if @to_email.nil?
        raise ArgumentError, 'Subject is required' if @subject.nil?
        raise ArgumentError, 'Content is required' if @content.nil?
      end

      def call
        begin
          sendgrid = SendGrid::API.new(api_key: @api_key)
          mail = build_mail
          response = sendgrid.client.mail._('send').post(request_body: mail.to_json)

          if response.status_code.to_i == 202
            log_info('Email sent successfully')
            { success: true, message: 'Email sent successfully' }
          else
            log_error("Failed to send email. Status code: #{response.status_code}")
            { success: false, message: "Failed to send email. Status code: #{response.status_code}" }
          end
        rescue => e
          log_error("Error sending email: #{e.message}")
          { success: false, message: "Error sending email: #{e.message}" }
        end
      end

      private

      def build_mail
        from = SendGrid::Email.new(email: @from_email)
        to = SendGrid::Email.new(email: @to_email)
        content = SendGrid::Content.new(type: 'text/plain', value: @content)
        mail = SendGrid::Mail.new(from, @subject, to, content)
        mail
      end

      def log_info(message)
        Sublayer.logger.info("[SendgridEmailAction] #{message}")
      end

      def log_error(message)
        Sublayer.logger.error("[SendgridEmailAction] #{message}")
      end
    end
  end
end