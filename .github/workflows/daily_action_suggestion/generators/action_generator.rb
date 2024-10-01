class ActionGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :named_strings,
    name: "action",
    description: "Generated Sublayer action",
    attributes: [
      { name: "file_path", description: "The full path and filename (ending with _action.rb) for the new action" },
      { name: "content", description: "The content of the new action file" }
    ]

  def initialize(idea:, action_examples:)
    @idea = idea
    @action_examples = action_examples
  end

  def generate
    super
  end

  def prompt
    <<-PROMPT
    Sublayer Actions are small, reusable classes for use in the Sublayer AI framework.
    They are designed to either get information from somewhere for sending to an LLM or for using information that was received by an LLM in some way.

    The following are examples of working Sublayer actions that are currently in use in different ways in the sublayer_actions repository:
    #{@action_examples}

    You are an AI assistant tasked with creating a new Sublayer action based on the following idea:

    Title: #{@idea.title}
    Description: #{@idea.description}

    Please generate a Sublayer action that implements this idea. The action should:
    1. Inherit from Sublayer::Actions::Base
    2. Have a meaningful name that reflects its purpose
    3. Implement the necessary methods (e.g., initialize, call)
    4. Include relevant error handling and logging
    5. Follow Ruby best practices and conventions
    6. Follow the convention of being stored in a folder named after the service or category it belongs to the way they are structured in the sublayer_actions repository above.

    Provide your response as:
    1. The full path and filename for the action (should end with _action.rb)
    2. The complete content of the action file

    Remember to make the action as specific as possible while keeping it simple to use.
    PROMPT
  end
end
