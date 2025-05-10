require 'postmark'

# Description: Sublayer::Action responsible for sending emails via the Postmark API.
# This action supports HTML content, attachments, and templated emails, making it ideal
# for AI systems that need to send professional communications.
#
# Requires: 'postmark' gem
# $ gem install postmark
# Or add `gem 'postmark'` to your Gemfile
#
# It is initialized with required email parameters and optional template/attachment details.
# It returns the message ID of the sent email from Postmark.
#
# Example usage: When you want to send AI-generated content via email using professionally
# designed templates or with formatted HTML content.

class PostmarkSendEmailAction < Sublayer::Actions::Base
  def initialize(
    to:,
    from:,
    subject:,
    body: nil,
    html_body: nil,
    template_id: nil,
    template_model: nil,
    attachments: nil,
    tag: nil
  )
    @to = to
    @from = from
    @subject = subject
    @body = body
    @html_body = html_body
    @template_id = template_id
    @template_model = template_model
    @attachments = attachments
    @tag = tag
    @client = Postmark::ApiClient.new(ENV['POSTMARK_API_TOKEN'])
  end

  def call
    begin
      if @template_id
        send_template_email
      else
        send_regular_email
      end
    rescue Postmark::ApiInputError => e
      error_message = "Invalid input for Postmark API: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Postmark::InternalServerError => e
      error_message = "Postmark server error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error sending email via Postmark: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def send_template_email
    response = @client.deliver_with_template(
      from: @from,
      to: @to,
      template_id: @template_id,
      template_model: @template_model,
      tag: @tag,
      attachments: process_attachments
    )
    
    Sublayer.configuration.logger.log(:info, "Template email sent successfully via Postmark. Message ID: #{response[:message_id]}")
    response[:message_id]
  end

  def send_regular_email
    response = @client.deliver(
      from: @from,
      to: @to,
      subject: @subject,
      text_body: @body,
      html_body: @html_body,
      tag: @tag,
      attachments: process_attachments
    )

    Sublayer.configuration.logger.log(:info, "Email sent successfully via Postmark. Message ID: #{response[:message_id]}")
    response[:message_id]
  end

  def process_attachments
    return nil unless @attachments

    @attachments.map do |attachment|
      {
        name: attachment[:name],
        content: Base64.encode64(attachment[:content]),
        content_type: attachment[:content_type]
      }
    end
  end
end