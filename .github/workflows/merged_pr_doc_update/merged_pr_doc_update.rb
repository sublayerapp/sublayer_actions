require "base64"

require "sublayer"
require "octokit"

# Load all Sublayer Actions, Generators, and Agents
Dir[File.join(__dir__, "actions", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "generators", "*.rb")].each { |file| require file }
Dir[File.join(__dir__, "agents", "*.rb")].each { |file| require file }

Sublayer.configuration.ai_provider = Sublayer::Providers::Gemini
Sublayer.configuration.ai_model = "gemini-2.0-flash"

# Add custom Github Action code below:

pr_number = ENV["PR_NUMBER"]

# Get Actions resources markdown file
file_content = GithubGetFileContentsAction.new(repo: "sublayerapp/sublayer_documentation", file_path: "docs/resources/actions.md").call
pr_contents = GetPRChangesAction.new(repo: "sublayerapp/sublayer_actions", pr_number: pr_number).call
updated_content = UpdateActionsMdContentGenerator.new(pr_contents: pr_contents, file_content: file_content).generate

branch_name = "pr-doc-update-#{pr_number}-#{Time.now.strftime("%Y-%m-%d-%H-%M-%S")}"

GithubCreateBranchAction.new(
  repo: "sublayerapp/sublayer_documentation",
  base_branch: "main",
  new_branch: branch_name
).call

GithubModifyFileAction.new(
  repo: "sublayerapp/sublayer_documentation",
  branch: branch_name,
  file_path: "docs/resources/actions.md",
  file_content: updated_content
).call

new_pr = GithubCreatePRAction.new(
  repo: "sublayerapp/sublayer_documentation",
  base: "main",
  head: branch_name,
  title: "Add new Sublayer::Action to resources from PR ##{pr_number}",
  body: "This PR adds a new Sublayer::Action to the resources documentation."
).call

GithubAddPRLabelAction.new(repo: "sublayerapp/sublayer_documentation", pr_number: new_pr.number, label: "ai-generated").call
GithubAddPRLabelAction.new(repo: "sublayerapp/sublayer_documentation", pr_number: new_pr.number, label: "gemini").call
