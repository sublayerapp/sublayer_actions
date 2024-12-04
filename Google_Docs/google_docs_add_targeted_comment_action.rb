# frozen_string_literal: true

# Description: Sublayer::Action for adding a targeted comment to a Google Doc.
# Allows specifying the comment's location within the document.

class GoogleDocsAddTargetedCommentAction < Sublayer::Actions::Base
  def initialize(document_id:, comment_text:, location: :end, paragraph_index: nil)
    @document_id = document_id
    @comment_text = comment_text
    @location = location
    @paragraph_index = paragraph_index

    @client = Google::Apis::DocsV1::DocsService.new
    @client.authorization = Google::Auth.get_application_default(scope: 'https://www.googleapis.com/auth/documents')
  end

  def call
    begin
      requests = build_requests
      @client.batch_update_document(@document_id, Google::Apis::DocsV1::BatchUpdateDocumentRequest.new(requests: requests))

      Sublayer.configuration.logger.log(:info, "Comment added successfully to document #{@document_id}")
    rescue StandardError => e
      error_message = "Error adding comment to Google Doc: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def build_requests
    case @location
    when :end
      create_end_of_document_comment_request
    when :paragraph
      raise ArgumentError, "paragraph_index is required when location is :paragraph" unless @paragraph_index

      create_paragraph_comment_request
    else
      raise ArgumentError, "Invalid location specified: #{@location}"
    end
  end

  def create_end_of_document_comment_request
    [
      Google::Apis::DocsV1::Request.new(
        insert_text:
          Google::Apis::DocsV1::InsertTextRequest.new(
            text: "\n\n#{@comment_text}",
            end_of_segment:
              Google::Apis::DocsV1::EndOfSegmentLocation.new(
                segment_id: ''
              )
          )
      ),
      Google::Apis::DocsV1::Request.new(
        create_footnote:
          Google::Apis::DocsV1::CreateFootnoteRequest.new(
            location:
              Google::Apis::DocsV1::Location.new(
                segment_id: '',
                index: 1 # index needs to be non-zero for comment creation.
              )
          )
      )
    ]
  end

  def create_paragraph_comment_request
    paragraph_id = get_paragraph_id(@paragraph_index)
    [
      Google::Apis::DocsV1::Request.new(
        create_footnote:
          Google::Apis::DocsV1::CreateFootnoteRequest.new(
            location:
              Google::Apis::DocsV1::Location.new(
                segment_id: paragraph_id,
                index: 1
              ),
            footnote:
              Google::Apis::DocsV1::Footnote.new(
                content: Google::Apis::DocsV1::StructuralElement.new(
                  paragraph: Google::Apis::DocsV1::Paragraph.new(
                    elements: [
                      Google::Apis::DocsV1::ParagraphElement.new(
                        text_run: Google::Apis::DocsV1::TextRun.new(content: @comment_text)
                      )
                    ]
                  )
                )
              )
          )
      )
    ]
  end

  def get_paragraph_id(index)
    document = @client.get_document(@document_id)
    document.body.content[index + 2].paragraph.paragraph_style.named_style_type
  rescue StandardError => e
      raise "Error getting paragraph ID: #{e}"
  end
end