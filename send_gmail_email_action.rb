require "google/apis/gmail_v1"

module Sublayer
  module Actions
    class SendGmailEmailAction < Sublayer::Actions::Base
      def initialize(params = {})
        super(params)

        # Required parameters
        @sender = params.fetch(:sender)
        @recipient = params.fetch(:recipient)
        @subject = params.fetch(:subject)
        @body = params.fetch(:body)

        # Optional parameters
        @attachments = params[:attachments] || []
      end

      def call
        service = Google::Apis::GmailV1::GmailService.new
        service.client_options.application_name = "Sublayer"
        service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
          scope: 'https://www.googleapis.com/auth/gmail.send'
        )

        message = build_message
        service.send_user_message('me', message)

        logger.info("Successfully sent email from #{@sender} to #{@recipient}")
      rescue StandardError => e
        logger.error("Error sending email: #{e.message}")
        raise e
      end

      private

      def build_message
        mail = Mail.new
        mail.from = @sender
        mail.to = @recipient
        mail.subject = @subject
        mail.text_part = { content_type: 'text/plain; charset=UTF-8', body: @body }

        @attachments.each do |attachment|
          mail.attachments[attachment[:filename]] = {
            mime_type: attachment[:mime_type],
            content: attachment[:content]
          }
        end

        message = Google::Apis::GmailV1::Message.new(raw: mail.to_s.encode("ASCII-8BIT"))
      end
    end
  end
end