# Description: Sublayer::Action responsible for performing mathematical calculations.
# Useful for situations where the AI might hallucinate numbers or perform inaccurate calculations.
#
# Example usage: When you want to calculate a final price after discount, or compute the sum of values extracted from text.

class MathematicalCalculationAction < Sublayer::Actions::Base
  def initialize(expression:)
    @expression = expression
  end

  def call
    begin
      result = evaluate_expression
      Sublayer.configuration.logger.log(:info, "Successfully evaluated expression: #{@expression} with result: #{result}")
      result
    rescue StandardError => e
      error_message = "Error evaluating mathematical expression: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def evaluate_expression
    # Basic safety check to prevent arbitrary code execution.
    # This can be expanded as needed, but be careful of unintended consequences.
    unless @expression =~ /^\A[0-9+\-\*\/(). ]+\z/
      raise SecurityError, "Invalid expression format. Only numbers, basic operators, parentheses, and spaces are allowed."
    end

    # Evaluate the expression using Ruby's eval function.
    # NOTE: Using eval can be dangerous if the input is not carefully validated.
    eval(@expression)
  end
end