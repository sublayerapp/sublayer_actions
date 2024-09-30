class ActionGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :named_strings,
    name: "action",
    description: "Generated Sublayer action",
    attributes: [
      { name: "filename", description: "The filename for the new action" },
      { name: "content", description: "The content of the new action file" }
    ]

  def initialize(idea:)
    @idea = idea
  end

  def generate
    super
  end

  def prompt
    <<-PROMPT
    You are an AI assistant tasked with creating a new Sublayer action based on the following idea:

    Title: #{@idea.title}
    Description: #{@idea.description}

    Please generate a Sublayer action that implements this idea. The action should:
    1. Inherit from Sublayer::Actions::Base
    2. Have a meaningful name that reflects its purpose
    3. Implement the necessary methods (e.g., initialize, call)
    4. Include relevant error handling and logging
    5. Follow Ruby best practices and conventions

    Provide your response as:
    1. A filename for the action (should end with _action.rb)
    2. The complete content of the action file

    Remember to make the action as useful and flexible as possible while keeping it simple to use.
    PROMPT
  end
end
