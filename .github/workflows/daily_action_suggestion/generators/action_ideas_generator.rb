class ActionIdeasGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :list_of_named_strings,
    name: "action_ideas",
    description: "List of sublayer action ideas with usefulness scores",
    item_name: "idea",
    attributes: [
      { name: "title", description: "The title of the action idea" },
      { name: "description", description: "A brief description of the action" },
      { name: "usefulness_score", description: "A score from 1-10 indicating the usefulness of the action with 10 being the best" }
    ]

  def initialize(code_context:, action_code_context:)
    @code_context = code_context
    @action_code_context = action_code_context
  end

  def generate
    super
  end

  def prompt
    <<-PROMPT
    You are an AI assistant tasked with generating ideas for new Sublayer actions.

    Sublayer actions are small, reusable units of functionality that can be combined to create more complex workflows.
    In the sublayer repo we have examples of using them in tests and you can see the base class.

    Sublayer repo contents:
    #{@code_context}

    Below is a repo of existing sublayer actions we've found to be useful in the past.

    Existing Sublayer actions:
    #{@action_code_context}

    Please generate a list of 5 ideas for new Sublayer actions that would be useful additions to the existing set.
    For each idea, provide:
    - A title
    - A brief description
    - A usefulness score from 1-10

    Focus on actions that would be generally useful and align well with Sublayer's goals and existing functionality.
    PROMPT
  end
end
