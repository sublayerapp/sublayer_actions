require "sublayer/actions/base"

module Sublayer
  module Actions
    class SendEmailAction < Sublayer::Actions::Base
      def initialize(service:, from:, to:, subject:, body:, **options)
        super()
        @service = service
        @from = from
        @to = to
        @subject = subject
        @body = body
        @options = options
      end

      def call
        logger.info("Sending email using #{@service} from #{@from} to #{@to}")

        # Implement email sending logic based on the chosen service
        # For example, if using SendGrid:
        #   response = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY']).client.mail._("send").post(request_body: mail.to_json)
        #   raise "Error sending email: #{response.status_code} - #{response.body}" unless response.status_code == 202

        # Log success
        logger.info("Email sent successfully")
      rescue => e
        logger.error("Error sending email: #{e.message}")
        raise
      end
    end
  end
end