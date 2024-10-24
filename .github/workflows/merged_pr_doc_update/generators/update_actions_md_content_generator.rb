class UpdateActionsMdContentGenerator < Sublayer::Generators::Base
  llm_output_adapter type: :single_string,
    name: "updated_content",
    description: "The updated content of the actions.md file"

  def initialize(pr_contents:, file_content:)
    @pr_contents = pr_contents
    @file_content = file_content
  end

  def prompt
    <<-PROMPT
    You are tasked with updating the following actions.md file with a new Sublayer::Action entry.

    Current content of actions.md:
    #{@file_content}

    The PR for the new entry to be added is:
    #{@pr_contents}

    Please update the actions.md content by adding the new action entry under the appropriate header.
    If the header does not exist, please create a new header for the action entry.

    Maintain the existing format and structure of the document.
    Ensure the new entry is added in alphabetical order within its category.

    Return the entire update content of the actions.md file including this new entry.
    PROMPT
  end
end
