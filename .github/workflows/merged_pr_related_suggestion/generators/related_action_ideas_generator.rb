class RelatedActionIdeasGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :list_of_named_strings,
    name: "action_ideas",
    description: "List of related Sublayer::Action ideas",
    item_name: "idea",
    attributes: [
      { name: "title", description: "Title of the Sublayer::Action idea" },
      { name: "description", description: "Description of the Sublayer::Action idea" },
      { name: "usefulness_score", description: "A score from 1-10 indicating how useful this action might be" }
    ]

    def initialize(pr_changes:, existing_actions:)
      @pr_changes = pr_changes
      @existing_actions = existing_actions
    end

    def generate
      super
    end

    def prompt
      <<-PROMPT
      You are an expert Ruby developer specializing in creating Sublayer::Actions.

      Sublayer::Actions are small, reusable, but very specific units of functionality that can be combined to create more complex workflows.

      Based on the following pull request changes and existing Sublayer::Actions,
      generate 5 ideas for new, related Sublayer::Actions that could be useful.

      Pull request changes:
      #{@pr_changes}

      Existing Sublayer::Actions:
      #{@existing_actions}

      For each idea, provide:
      - title: concise title for the Sublayer::Action
      - description: A brief description of what the action does and why it's useful
      - usefulness_score: A score from 1-10 indicating how useful this action might be

      Focus on cre3ating actions that complement or extend the functionality introduced in the PR changes.
      PROMPT
    end
end
