class SublayerActionUseCaseGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :list_of_strings,
    name: "use_cases",
    description: "List of potential use cases for the Sublayer::Action"

  def initialize(pr_changes:)
    @pr_changes = pr_changes
  end

  def prompt
    <<~PROMPT
      A PR was just merged into the Sublayer::Actions repository and we need to generate some potential use cases for the new action for inspiration.

      Sublayer::Actions are used similarly to tools in other agent frameworks. They're designed
      to be used to get information from external sources to be used in prompts or to perform actions on external services in response to
      responses received from AI models.

      The following PR was just merged: #{@pr_changes}

      Generate 3 potential, practical, and useful use cases for the new Sublayer::Action.

      Each use case should be a brief, practical example of how this action could be used in an AI automation scenario.
    PROMPT
  end
end
