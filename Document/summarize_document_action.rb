# Description: Sublayer::Action responsible for generating a concise summary of a long document or article.
# It inherits from Sublayer::Actions::Base which handles initialization and standard functionality.
#
# It is initialized with a document (as a string) and uses an external summarization library or API to generate the summary.
# Example usage: When you have a lengthy text and want to quickly understand the key points by generating a summary.

require 'summarize_library' # hypothetical library for summarization, replace with actual library/API

class SummarizeDocumentAction < Sublayer::Actions::Base
  def initialize(document:)
    @document = document
    @logger = Sublayer.configuration.logger
  end

  def call
    begin
      summary = generate_summary(@document)
      @logger.log(:info, "Document summarized successfully.")
      summary
    rescue StandardError => e
      @logger.log(:error, "Error summarizing document: #{e.message}")
      raise e
    end
  end

  private

  def generate_summary(document)
    # This is a placeholder; replace with logic to use a real summarization library or service
    SummarizeLibrary.summarize(document)
  end
end
