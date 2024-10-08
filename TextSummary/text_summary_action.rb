# Description: Sublayer::Action responsible for summarizing large texts into concise points using an AI model.
# This action is intended to be used for condensing meeting minutes, reports, or other lengthy documents into shorter summaries.
#
# Example usage: When you have a lengthy report or meeting minutes that you want summarized into key points for easier digestion.

class TextSummaryAction < Sublayer::Actions::Base
  def initialize(text:, model: "default-model", **options)
    @text = text
    @model = model
    @options = options
  end

  def call
    summarized_text = summarize_text(@text, @model, @options)
    Sublayer.configuration.logger.log(:info, "Text summarized successfully")
    summarized_text
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error summarizing text: #{e.message}")
    raise e
  end

  private

  def summarize_text(text, model, options)
    # Mock implementation of text summary - replace with actual AI model call.
    "Summarized Points: This is a mock summary of the text."
  end
end
